#!/usr/bin/perl
#
# Script de sync de imagens do WordPress com o AWS S3
#
# Funcionalidades:
#
#   - Verifica se existem arquivos novos a serem copiados para o S3 com base da data atual
#   - Copia os arquivos respeitando o modelo de ano/mes/dia do WordPress
#   - Deleta imagens removidas do WordPress do S3
#   - Otimiza imagens JPEG e PNG
#   - Grava log dos arquivos copiados com data e nome do arquivos
#
#   Dependencias
#
#   - File::Monitor
#   - Log::Log4perl
#   - File::Pid
#   - File:Type
#   - Log::Dispatch::FileRotate
#

use warnings;
use File::Pid;
use File::Monitor;
use File::Monitor::Delta;
use File::Type;
use Log::Log4perl;
use File::Basename;
use POSIX qw(strftime);
use Data::Dumper;
 
my $logConfigFile = "/etc/s3sync/log4perl_genet.conf";
my $s3Bucket = "s3://bucket_da_amazon/";
my $scriptLockFile = File::Pid->new({ file => '/var/run/s3sync.pid', });
my $wpDirectory = "wp-content/uploads/";
my $dataDirectory = "path_absoluto_para_a_raiz_do_wordpress";
my $datestring = strftime "%Y/%m/%d", localtime;
my $watchDirectory = "$dataDirectory"."$wpDirectory"."$datestring";
my $s3Destination = "$s3Bucket"."$wpDirectory"."$datestring";
my $s3Options = "--acl public-read --delete --cache-control 'public, max-age=2592000'";

# log4perl #
Log::Log4perl::init($logConfigFile);
$logger = Log::Log4perl->get_logger();
$logger->info("Iniciando S3 Sync");
$logger->info("--------------------------");

# funções #
sub imageDirector {
    $datestring = strftime "%Y/%m/%d", localtime;
    $watchDirectory = "$dataDirectory"."$wpDirectory"."$datestring";
    return $watchDirectory;
}
 
sub s3Director {
    $datestring = strftime "%Y/%m/%d", localtime;
    $s3Destination = "$s3Bucket"."$wpDirectory"."$datestring";
    return $s3Destination;
}

sub imageOptimize {
    $filetype = File::Type->new();
    foreach $image (@adds) {
        $type = $filetype->mime_type($image);
        $logger->info("Otimizando imagem $image");
        if ("$type" eq "image/jpeg"){
            system("/usr/bin/jpegoptim -s --all-progressive $image > /dev/null");
        }
        elsif ("$type" eq "image/x-png"){
            system("/usr/bin/pngquant -f $image > /dev/null");
        }
    }
}

sub dirMonitor {
        $monitor = File::Monitor->new();
        $monitor->watch( {
                name    => $watchDirectory,
                recurse     => 1,
        } );
}

&dirMonitor($watchDirectory);

# script #
for(;;){
    $auxdatestring = strftime "%Y/%m/%d", localtime;
    if ("$auxdatestring" ne "$datestring"){
        $watchDirectory = imageDirector();
        $s3Destination = s3Director();
        &dirMonitor($watchDirectory);
    }
        for my $change ($monitor->scan){
                @adds = $change->files_created;
        @dels = $change->files_deleted;
        &imageOptimize(@adds);
        system("/usr/bin/aws s3 sync $watchDirectory $s3Destination $s3Options > /dev/null");
        foreach $image (@adds){
            $logger->info("Copiando imagem $image");
        }
        foreach $image (@dels){
            $logger->info("Removendo imagem $image");
        }
        $logger->info("Sync efetuado com sucesso");
        $logger->info("--------------------------");
        }
        sleep(3);
}