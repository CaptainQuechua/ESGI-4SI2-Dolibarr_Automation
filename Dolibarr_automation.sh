#!/bin/bash

# Fonction pour vérifier si l'utilisateur a exécuté le script avec les droits root
sudo_verif(){
    if [ "$EUID" -ne 0 ]; then
        echo "Ce script doit être exécuté en tant que root. Veuillez le relancer avec les droits adéquats."
        exit 1
    fi
}

# Fonction pour gérer les erreurs
if_error() {
    if [ $? -ne 0 ]; then
        echo "Erreur : $1"
        exit 1
    fi
}

# Fonction pour afficher un warning au user sur la modification de ses fichiers de configuration réseau
warning() {
    echo "ATTENTION : Une sauvegarde des fichiers suivants sera réalisée car ils vont être écrasés :"
    echo " - /etc/hosts"
    echo " - /etc/network/interfaces"
    echo ""
    echo "Voulez-vous continuer ?"
    echo "1) Oui"
    echo "2) Non"

    read -p "Choisissez '1' pour Oui ou '2' pour Non : " choice
    case $choice in
        1)
            echo "Démarrage du script."
            ;;
        2)
            echo "Exécution du script annulée."
            exit 0
            ;;
        *)
            echo "Option invalide. Veuillez choisir 1 ou 2."
            exit 1
            ;;
    esac
}

# Fonction pour sauvegarder les fichiers de configuration réseau
backup_network() {
    cp /etc/hosts /etc/hosts.bak
    if_error "Erreur lors de la sauvegarde du fichier /etc/hosts."

    cp /etc/network/interfaces /etc/network/interfaces.bak
    if_error "Erreur lors de la sauvegarde du fichier /etc/network/interfaces."

    echo "Sauvegarde des fichiers 'hosts' et 'interfaces' terminée."
}

# Fonction pour vérifier et installer les paquets nécessaires
install_dependencies() {
    echo "Vérification et installation des dépendances en cours..."
    apt update -qq > /dev/null
    for pkg in apache2 mariadb-server php php-mysql libapache2-mod-php wget unzip; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            echo "Le paquet $pkg n'est pas installé. Installation en cours..."
            apt install -y -qq "$pkg" > /dev/null 2>&1
            if_error "Erreur lors de l'installation du paquet $pkg."
        else
            echo "Le paquet $pkg est déjà installé."
        fi
    done
}

# Fonction pour configurer MariaDB
configure_mariadb() {
    echo "Configuration de MariaDB en cours..."
    
    read -p "Entrez le nom de la base de données à créer : " db_name
    read -p "Entrez le nom d'utilisateur de la base de données : " db_user
    read -sp "Entrez le mot de passe pour cet utilisateur de la base de données : " db_pass
    echo

    mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE ${db_name};
CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    if_error "Erreur lors de la configuration de MariaDB."

    echo "La base de données '${db_name}' et l'utilisateur '${db_user}' ont été créés avec succès."
}

# Fonction pour la configuration de Apache2
configure_apache() {
    echo "Configuration du serveur web Apache en cours..."
    
    cat <<EOL >/etc/apache2/sites-available/dolibarr.conf
<VirtualHost *:80>
    ServerName $domain_name
    DocumentRoot /var/www/dolibarr/htdocs
    <Directory /var/www/dolibarr/htdocs>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

    if_error "Erreur lors de la configuration d'Apache."

    a2ensite dolibarr.conf > /dev/null 2>&1
    if_error "Erreur lors de l'activation du site Dolibarr pour Apache."

    a2enmod rewrite > /dev/null 2>&1
    if_error "Erreur lors de l'activation du module rewrite pour Apache."

    systemctl reload apache2 > /dev/null 2>&1
    if_error "Erreur lors du redémarrage du service Apache."

    echo "Apache configuré avec succès."
}

#Fonction pour la configuration de l'interface réseau et de son IP en statique
configure_ip() {
    echo "Voulez-vous détecter automatiquement l'interface réseau ou entrer le nom de l'interface manuellement ?"
    echo "1) Automatique"
    echo "2) Manuel"

    read -p "Choisissez '1' pour Automatique ou '2' pour Manuel : " choice
    case $choice in
        1)
            interface=$(ip -o -4 route show to default | awk '{print $5}')
            if_error "Erreur lors de la détection automatique de l'interface réseau."
            echo "Interface réseau détectée automatiquement : $interface"
            ;;
        2)
            read -p "Entrez le nom de l'interface réseau (ex: eth0, enp0s3...) : " interface
            echo "Interface réseau choisie manuellement : $interface"
            ;;
        *)
            echo "Option invalide. Veuillez choisir 1 ou 2."
            exit 1
            ;;
    esac

    read -p "Entrez l'adresse IP fixe : " ip_address
    read -p "Entrez l'adresse du masque de sous-réseau : " subnet_mask
    read -p "Entrez la passerelle par défaut : " gateway

    echo "Modification de /etc/network/interfaces en cours..."
    cat <<EOL >/etc/network/interfaces
auto lo
iface lo inet loopback

auto $interface
iface $interface inet static
    address $ip_address
    netmask $subnet_mask
    gateway $gateway
EOL

    if_error "Erreur lors de la configuration de l'IP statique."

    systemctl restart networking
    if_error "Erreur lors du redémarrage du service networking."

    echo "Adresse IP $ip_address configurée sur l'interface $interface."
}

# Fonction pour l'installation de Dolibarr
install_dolibarr() {
    if [ ! -f dolibarr.zip ]; then
        echo "Téléchargement et installation de Dolibarr en cours..."
        wget --quiet --wait=10 --timeout=30 --tries=3 -O dolibarr.zip https://sourceforge.net/projects/dolibarr/files/Dolibarr%20ERP-CRM/20.0.0/dolibarr-20.0.0.zip/download
        if_error "Erreur lors du téléchargement de Dolibarr."
    else
        echo "Le fichier dolibarr.zip est déjà présent, pas besoin de télécharger."
    fi

    if [ ! -d /var/www/dolibarr ]; then
        mkdir -p /var/www/dolibarr
        if_error "Erreur lors de la création du répertoire /var/www/dolibarr."
    fi

    unzip -qq dolibarr.zip -d /var/www/
    if_error "Erreur lors de l'extraction de Dolibarr."

    mv /var/www/dolibarr-20.0.0/* /var/www/dolibarr
    chown -R www-data:www-data /var/www/dolibarr
    chmod -R 755 /var/www/dolibarr

    echo "Dolibarr installé avec succès."
}

# Fonction pour ajouter le nom de domaine dans le fichier hosts
configure_hosts() {
    echo "Modification de /etc/hosts en cours..."

    cat <<EOL >/etc/hosts
127.0.0.1   localhost
127.0.1.1   $domain_name

::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOL

    if_error "Erreur lors de la modification du fichier /etc/hosts."

    echo "Configuration de /etc/hosts terminée."
}

# Foncion pour redémarrer l'ensemble des services
restart_all() {
    echo "Redémarrage de l'ensemble des services nécessaires à l'utilisation de Dolibarr en cours..."
    
    systemctl restart networking
    if_error "Erreur lors du redémarrage du service networking."

    systemctl restart mariadb
    if_error "Erreur lors du redémarrage du service MariaDB."

    systemctl restart apache2
    if_error "Erreur lors du redémarrage du service Apache."

    echo "Tous les services ont été redémarrés avec succès."
}

# Fonction pour effectuer le nettoyage des fichiers
clean() {
    rm dolibarr.zip
    rm -rf /var/www/dolibarr-20.0.0
    if_error "Erreur lors du nettoyage."

    echo "Nettoyage des fichiers terminé."
}

# Appel des fonctions
sudo_verif
warning
read -p "Entrez le nom de domaine pour Dolibarr (ex: doli.4si2.lab) : " domain_name
backup_network
install_dependencies
configure_mariadb
install_dolibarr
configure_apache
configure_ip
configure_hosts
restart_all
clean

echo "Installation terminée. Veuillez accéder à Dolibarr via votre nom de domaine."

exit 0