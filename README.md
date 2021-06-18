# Photonix for YunoHost

[![Integration level](https://dash.yunohost.org/integration/photonix.svg)](https://dash.yunohost.org/appci/app/photonix) ![](https://ci-apps.yunohost.org/ci/badges/photonix.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/photonix.maintain.svg)  
[![Install photonix with YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=photonix)

*[Lire ce readme en français.](./README_fr.md)*

> *This package allows you to install Photonix quickly and simply on a YunoHost server.  
If you don't have YunoHost, please consult [the guide](https://yunohost.org/#/install) to learn how to install it.*

## Overview
Photonix is a photo management application that streamlines the process of storing, presenting and re-discovering photos. Smart filtering is made possible automatically by object recognition, location awareness, color analysis and other algorithms.

**Shipped version:** 0.9.0

## Screenshots

![](https://camo.githubusercontent.com/8010d9b6f3b32fecc5cde4ba6601ad17f3e9098b788e3bf1972989d003f8ace3/68747470733a2f2f6570697873747564696f732e636f2e756b2f75706c6f6164732f66696c65725f7075626c69632f35322f64632f35326463646666342d643936642d346466642d623135382d6235376230363936313534652f70686f746f5f6c6973742e6a7067)

## Demo

* [Official demo](https://demo.photonix.org/)

## Configuration

There is an admin panel accessible from `https://your.domian.tld/admin/`.

## Documentation

* Official documentation: https://photonix.org/docs/

## YunoHost specific features

* LDAP SSO
* Automatic creation of libraries from multimedia directories

#### Multi-user support

Are LDAP and HTTP auth supported? **LDAP only**
Can the app be used by multiple users? **Yes**

#### Supported architectures

* x86-64 - [![Build Status](https://ci-apps.yunohost.org/ci/logs/photonix.svg)](https://ci-apps.yunohost.org/ci/apps/photonix/)
* ARMv8-A - [![Build Status](https://ci-apps-arm.yunohost.org/ci/logs/photonix.svg)](https://ci-apps-arm.yunohost.org/ci/apps/photonix/)

## Limitations

* The upstream app has not yet had a stable release, there may be bugs.

## Links

* Report a bug: https://github.com/YunoHost-Apps/photonix_ynh/issues
* App website: https://photonix.org/
* Upstream app repository: https://github.com/photonixapp/photonix/
* YunoHost website: https://yunohost.org/

---

## Developer info

**Only if you want to use a testing branch for coding, instead of merging directly into master.**
Please send your pull request to the [testing branch](https://github.com/YunoHost-Apps/photonix_ynh/tree/testing).

To try the testing branch, please proceed like that.
```
sudo yunohost app install https://github.com/YunoHost-Apps/photonix_ynh/tree/testing --debug
or
sudo yunohost app upgrade photonix -u https://github.com/YunoHost-Apps/photonix_ynh/tree/testing --debug
```
