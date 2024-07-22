# Docker build

 `docker-build.sh` (re)builds images

After starting the script, Docker downloads glftpd and (if enabled) zs/bot component. It puts them into image with init & startup script and then builds it: `docker build ./docker-run.sh --cache-from docker-glftpd:2.13 --tag docker-glftpd:<VERSION> --tag docker-glftpd:latest` (plus any build-args).

The image name will be tagged `glftpd:latest`. If you enabled the web interface, a `docker-glftpd-web:latest` image is also build.

Options work the same as docker-run script.

For all available build args, see comments inside [/docker-build.sh](/docker-build.sh).
