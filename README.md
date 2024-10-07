# ESGI-4SI2-Dolibarr_Automation

Ce projet a été réalisé dans le cadre des cours de 4e année de Sécurité Informatique à l'ESGI. L'objectif est d'automatiser l'installation et la configuration de **Dolibarr ERP-CRM** sur une machine Debian fraîchement installée.

## Description

Le script bash fourni dans ce projet permet une installation entièrement automatisée de Dolibarr, en prenant en charge l'installation des dépendances nécessaires, la configuration de MariaDB, la configuration réseau, ainsi que la configuration d'Apache2. Ce script est conçu pour être lancé juste après l'installation de Debian et inclut la configuration de la base de données, des fichiers réseau et du serveur web pour que l'utilisateur puisse accéder à Dolibarr via un nom de domaine spécifique.

## Fonctionnalités
- **Installation automatisée des dépendances :** Apache, MariaDB, PHP, etc.
- **Configuration personnalisable de MariaDB :** Possibilité de définir le nom de la base de données, le nom d'utilisateur et le mot de passe.
- **Détection automatique ou manuelle de l'interface réseau :** Pour la configuration de l'IP statique.
- **Installation et configuration de Dolibarr :** Téléchargement automatique, extraction et mise en place des fichiers.
- **Configuration d'Apache avec un VirtualHost :** Pour permettre l'accès à Dolibarr via un nom de domaine.
- **Sauvegarde automatique des fichiers systèmes sensibles :** Avant modification des fichiers `/etc/hosts` et `/etc/network/interfaces`.
- **Redémarrage automatique des services :** Apache, MariaDB et les services réseau sont redémarrés après l'installation.

## Prérequis
- Une machine Debian fraîchement installée.
- Connexion internet active pour le téléchargement des dépendances et de Dolibarr.
- Accès root ou sudo pour l'exécution du script.

## Installation

1. **Téléchargement du script :**
   Clonez ou téléchargez ce dépôt sur votre machine Debian :
   ```bash
   git clone https://github.com/username/ESGI-4SI2-Dolibarr_Automation.git
   cd ESGI-4SI2-Dolibarr_Automation
   ```

2. **Exécution du script :**
   Assurez-vous que le script dispose des droits d'exécution :
   ```bash
   chmod +x Dolibarr_automation.sh
   ```

   Lancez ensuite le script avec des droits `sudo` ou directement en tant que root :
   ```bash
   sudo ./Dolibarr_automation.sh
   ```

3. **Configuration :**
   Pendant l'exécution, le script vous demandera de :
   - Choisir un nom de domaine pour Dolibarr.
   - Définir le nom de la base de données, l'utilisateur et le mot de passe MariaDB.
   - Configurer une adresse IP statique.

## Utilisation
Une fois l'installation terminée, vous pouvez accéder à Dolibarr via le nom de domaine que vous avez configuré, par exemple : `http://doli.4si2.lab`.

## Sauvegarde et restauration

Le script effectue automatiquement des sauvegardes des fichiers `/etc/hosts` et `/etc/network/interfaces` avant de les modifier. Si nécessaire, vous pouvez restaurer ces fichiers en remplaçant les fichiers actuels par les fichiers de sauvegarde (`/etc/hosts.bak` et `/etc/network/interfaces.bak`).

## Démonstration
Vous pouvez consulter une démonstration vidéo du script en action sur YouTube :  
[**Vidéo de test et démonstration**](https://youtu.be/Sc7pGvk3e3Y)