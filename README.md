# s3sync

Daemon perl para otimização e sync de imagens com o S3

Ajustar as variáveis dos scripts para definir os paths de acordo com seu ambiente

Utilização:

	- Copiar o s3sync.pl para o diretório de binários do S.O. com o nome s3sync (Ex.: /usr/bin/s3sync
	- Copiar o s3sync para /etc/init.d/
	- Iniciar, parar ou restartar o serviço utilizando o script do init.d

Funcionalidades:

	- Verifica se existem arquivos novos a serem copiados para o S3 com base da data atual
	- Copia os arquivos respeitando o modelo de ano/mes/dia do WordPress
	- Deleta imagens removidas do WordPress do S3
	- Otimiza imagens JPEG e PNG
	- Grava log dos arquivos copiados com data e nome do arquivos

Dependencias

	- File::Monitor
	- Log::Log4perl
	- File::Pid
	- File:Type
	- Log::Dispatch::FileRotate