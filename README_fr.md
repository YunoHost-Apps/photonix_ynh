# Photonix pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/photonix.svg)](https://dash.yunohost.org/appci/app/photonix) ![](https://ci-apps.yunohost.org/ci/badges/photonix.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/photonix.maintain.svg)  
[![Installer photonix avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=photonix)

*[Read this readme in english.](./README.md)*

> *Ce package vous permet d'installer Photonix rapidement et simplement sur un serveur YunoHost.  
Si vous n'avez pas YunoHost, consultez [le guide](https://yunohost.org/#/install) pour apprendre comment l'installer.*

## Vue d'ensemble
Photonix est une application de gestion de photos qui simplifie le processus de stocker, présenter er re-découvrir ses photos. Le filtrage intelligent est rendu possible automatiquement grâce à la reconnaissance d'objets, la localisation, l'analyse de couleurs, et d'autres algorithmes.

**Version incluse :** 2021-05-03

## Captures d'écran

![](https://camo.githubusercontent.com/8010d9b6f3b32fecc5cde4ba6601ad17f3e9098b788e3bf1972989d003f8ace3/68747470733a2f2f6570697873747564696f732e636f2e756b2f75706c6f6164732f66696c65725f7075626c69632f35322f64632f35326463646666342d643936642d346466642d623135382d6235376230363936313534652f70686f746f5f6c6973742e6a7067)

## Démo

* [Démo officielle](https://demo.photonix.org/)

## Configuration

Un panneau admin est accessible depuis `https://votre.domiane.tld/admin/`.

## Documentation

* Documentation officielle : https://photonix.org/docs/

## Caractéristiques spécifiques YunoHost

* SSO LDAP
* Création automatique des bibliothèques à partir des dossiers multimédia

#### Support multi-utilisateur

* L'authentification LDAP et HTTP est-elle prise en charge ? **Seulement LDAP**
* L'application peut-elle être utilisée par plusieurs utilisateurs ? **Oui**

#### Architectures supportées

* x86-64 - [![Build Status](https://ci-apps.yunohost.org/ci/logs/photonix.svg)](https://ci-apps.yunohost.org/ci/apps/photonix/)
* ARMv8-A - [![Build Status](https://ci-apps-arm.yunohost.org/ci/logs/photonix.svg)](https://ci-apps-arm.yunohost.org/ci/apps/photonix/)

## Limitations

* L'application d'origine n'a pas encore eue de version stable, il pourrait y avoir des bugs.

## Liens

* Signaler un bug : https://github.com/YunoHost-Apps/photonix_ynh/issues
* Site de l'application : https://photonix.org/
* Dépôt de l'application principale : https://github.com/photonixapp/photonix/
* Site web YunoHost : https://yunohost.org/

---

## Informations pour les développeurs

**Seulement si vous voulez utiliser une branche de test pour le codage, au lieu de fusionner directement dans la banche principale.**
Merci de faire vos pull request sur la [branche testing](https://github.com/YunoHost-Apps/photonix_ynh/tree/testing).

Pour essayer la branche testing, procédez comme suit.
```
sudo yunohost app install https://github.com/YunoHost-Apps/photonix_ynh/tree/testing --debug
ou
sudo yunohost app upgrade photonix -u https://github.com/YunoHost-Apps/photonix_ynh/tree/testing --debug
```
