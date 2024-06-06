#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# dependencies used by the app
#REMOVEME? pkg_dependencies="acl python3 python3-pip python3-venv nodejs postgresql postgresql-contrib postgresql-common redis-server libsasl2-dev libldap2-dev libssl-dev build-essential curl gfortran gnupg libatlas-base-dev libblas-dev libblas3 libfreetype6 libfreetype6-dev libhdf5-dev libheif-examples libjpeg-dev liblapack-dev liblapack3 libpq-dev libtiff5-dev netcat libimage-exiftool-perl"

#=================================================
# PERSONAL HELPERS
#=================================================

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

function set_permissions {
	mkdir -p "$install_dir/srv"
	chown -R root:$app "$install_dir"
	chmod -R g=u,g-w,o-rwx "$install_dir"
	setfacl -n -m g:www-data:--x "$install_dir";
	setfacl -nR -m d:g:www-data:r-x -m g:www-data:r-x "$install_dir/srv";

	mkdir -p "$data_path/data/"{photos,raw-photos-processed,cache,models}
	chown -R $app:$app "$data_path"
	chmod -R g=u,g-w,o-rwx "$data_path"
	setfacl -n -m g:www-data:--x "$data_path";
	setfacl -nR -m d:g:www-data:r-x -m g:www-data:r-x "$data_path/data";


	mkdir -p "/var/log/$app"
	chmod o-rwx "/var/log/$app"
}

function patch_files {
	find "$install_dir" -type f | while read file; do
		ynh_replace_string -m "'/srv" -r "'$install_dir/srv" -f "$file"
		ynh_replace_string -m "'/data" -r "'$data_path/data" -f "$file"
	done

	set_permissions
}

function build_django_backend {
	chown -R $app:$app "$install_dir"
	pushd "$install_dir"
		sudo -u $app python3 -m venv "$install_dir/venv"
		sudo -u $app $install_dir/venv/bin/pip --cache-dir "$install_dir/.cache/pip" install -U wheel pip setuptools 2>&1
		while read requirement ; do
			if [ ! -z "$requirement" ] && [[ ! "$requirement" =~ ^'#'.*  ]]; then
				sudo -u $app PYTHONUNBUFFERED=1 "$install_dir/venv/bin/pip" --cache-dir "$install_dir/.cache/pip" install "$requirement" 2>&1
			fi
		done < "$install_dir/requirements.txt"
		sudo -u $app $install_dir/venv/bin/pip --cache-dir "$install_dir/.cache/pip" install -U django-auth-ldap 2>&1
		sudo -u $app mkdir -p "$install_dir/srv"
		sudo -u $app cp -rT "$install_dir/photonix" "$install_dir/srv/photonix"
	popd
	pushd "$install_dir/srv"
		sudo -u $app $install_dir/venv/bin/python "$install_dir/srv/photonix/manage.py" collectstatic --noinput --link 2>&1
	popd

	set_permissions
}

function set_node_vars {
	ynh_exec_warn_less ynh_install_nodejs --nodejs_version=14
	ynh_use_nodejs
	node_path=$nodejs_path:$(sudo -u $app sh -c 'echo $PATH')
}

function build_node_frontend {
	set_node_vars

	chown -R $app:$app "$install_dir"
	sudo -u $app touch "$install_dir/.yarnrc"
	sudo -u $app mkdir -p "$install_dir/srv/ui"
	pushd "$install_dir"
		sudo -u $app cp -T "$install_dir/ui/package.json" "$install_dir/srv/ui/package.json"
		sudo -u $app cp -T "$install_dir/ui/yarn.lock" "$install_dir/srv/ui/yarn.lock"
	popd

	pushd "$install_dir/srv/ui"
		sudo -u $app env "PATH=$node_path" yarn --cache-folder $install_dir/yarn-cache --use-yarnrc $install_dir/.yarnrc install 2>&1
		sudo -u $app cp -rT "$install_dir/ui/public" "$install_dir/srv/ui/public"
		sudo -u $app cp -rT "$install_dir/ui/src" "$install_dir/srv/ui/src"
		sudo -u $app env "PATH=$node_path" yarn --cache-folder $install_dir/yarn-cache --use-yarnrc $install_dir/.yarnrc build 2>&1
	popd

	sudo -u $app cp -rT "$install_dir/ui/public" "$install_dir/srv/ui/public"

	set_permissions
}

function add_envfile {
#REMOVEME? 	secret_key=$(ynh_app_setting_get --app=$app --key=secret_key)

	if [ -z $secret_key ]; then
		secret_key=$(ynh_string_random -l 64)
		ynh_app_setting_set --app=$app --key=secret_key --value=$secret_key
	fi

	ynh_add_config --template="photonix.env" --destination="$install_dir/photonix.env"

	set_permissions
}

function apply_db_migrations {
	pushd "$install_dir/srv/photonix" || ynh_die
		sudo -u $app bash -c "
			source \"$install_dir/venv/bin/activate\"
			set -a
			source \"$install_dir/photonix.env\"
			python \"$install_dir/photonix/manage.py\" makemigrations
			python \"$install_dir/photonix/manage.py\" migrate"
	popd
}

services="app_server watch_photos raw_scheduler raw_processor thumbnail_processor classification_scheduler classification_color_processor classification_location_processor classification_face_detection_processor classification_style_processor classification_object_processor classification_event_processor rescan_photos_periodically"

function set_up_logrotate {
	local i=0
	for service in $services; do
		if (($i == 0)); then
			ynh_use_logrotate --logfile="/var/log/$app/$app-$service.log"
		else
			ynh_use_logrotate --logfile="/var/log/$app/$app-$service.log" --nonappend
			i=1
		fi
	done
}

function add_systemd_configs {
	for service in $services; do
		ynh_add_systemd_config --service=$app-$service --template=$service.service
	done
}

function remove_systemd_configs {
	for service in $services; do
		ynh_remove_systemd_config --service=$app-$service
	done
}

function integrate_services {
	for service in $services; do
		yunohost service add $app-$service --description="Photonix $service" --log="/var/log/$app/$app-$service.log"
	done
}

function remove_service_integrations {
	for service in $services; do
		yunohost service remove $app-$service
	done
}

function start_services {
	for service in $services; do
		ynh_systemd_action --service_name=$app-$service --action="start" --log_path="/var/log/$app/$app-$service.log"
	done
}

function stop_services {
	for service in $services; do
		ynh_systemd_action --service_name=$app-$service --action="stop" --log_path="/var/log/$app/$app-$service.log"
	done
}

function backup_services {
	for service in $services; do
		ynh_backup --src_path="/etc/systemd/system/$app-$service.service"
	done
}

function load_settings {
#REMOVEME? #REMOVEME? 	install_dir="$(ynh_app_setting_get --app=$app --key=install_dir)"
#REMOVEME? 	data_path="$(ynh_app_setting_get --app=$app --key=data_path)"
#REMOVEME? 	domain=$(ynh_app_setting_get --app=$app --key=domain)
#REMOVEME? 	path=$(ynh_app_setting_get --app=$app --key=path)
#REMOVEME? 	db_name=$(ynh_app_setting_get --app=$app --key=db_name)
	db_user=$db_name
#REMOVEME? 	db_pwd=$(ynh_app_setting_get --app=$app --key=psqlpwd)
#REMOVEME? 	admin=$(ynh_app_setting_get --app=$app --key=admin)
#REMOVEME? 	port=$(ynh_app_setting_get --app=$app --key=port)
#REMOVEME? 	classification_color_enabled=$(ynh_app_setting_get --app=$app --key=classification_color_enabled)
#REMOVEME? 	classification_location_enabled=$(ynh_app_setting_get --app=$app --key=classification_location_enabled)
#REMOVEME? 	classification_face_enabled=$(ynh_app_setting_get --app=$app --key=classification_face_enabled)
#REMOVEME? 	classification_style_enabled=$(ynh_app_setting_get --app=$app --key=classification_style_enabled)
#REMOVEME? 	classification_object_enabled=$(ynh_app_setting_get --app=$app --key=classification_object_enabled)
}

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
