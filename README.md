# apache-fpm-webserver
Hardened Apache + PHP-FPM builds based on ddev/ddev-webserver-prod.

## Usage

To build and test a ddev based image against the drupal 11 container:

```bash
just prereqs
just ddev-build
just k3d
```