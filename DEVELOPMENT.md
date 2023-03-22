Development
===========

Setting up the environment
--------------------------

WordPress will start in local Kubernetes (inside docker) using Skaffold. Every [CTRL] + [S] will trigger rebuilding the container and reinstalling the WordPress.

```yaml
make -f env.mk k3d dev
```
