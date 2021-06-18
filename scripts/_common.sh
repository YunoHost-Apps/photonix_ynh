#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# dependencies used by the app
pkg_dependencies="acl python3 python3-pip python3-venv nodejs postgresql postgresql-contrib postgresql-common redis-server libsasl2-dev libldap2-dev libssl-dev build-essential curl gfortran gnupg libatlas-base-dev libblas-dev libblas3 libfreetype6 libfreetype6-dev libhdf5-dev libjpeg-dev liblapack-dev liblapack3 libpq-dev libtiff5-dev netcat libimage-exiftool-perl"

#=================================================
# PERSONAL HELPERS
#=================================================

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

function set_permissions {
	mkdir -p "$final_path/srv"
	chown -R root:$app "$final_path"
	chmod -R g=u,g-w,o-rwx "$final_path"
	setfacl -n -m g:www-data:--x "$final_path";
	setfacl -nR -m d:g:www-data:r-x -m g:www-data:r-x "$final_path/srv";

	mkdir -p "$data_path/data/"{photos,raw-photos-processed,cache,models}
	chown -R $app:$app "$data_path"
	chmod -R g=u,g-w,o-rwx "$data_path"
	setfacl -n -m g:www-data:--x "$data_path";
	setfacl -nR -m d:g:www-data:r-x -m g:www-data:r-x "$data_path/data";


	mkdir -p "/var/log/$app"
	chmod o-rwx "/var/log/$app"
}

function patch_files {
	find "$final_path" -type f | while read file; do
		ynh_replace_string -m "'/srv" -r "'$final_path/srv" -f "$file"
		ynh_replace_string -m "'/data" -r "'$data_path/data" -f "$file"
	done

	set_permissions
}

function build_django_backend {
	chown -R $app:$app "$final_path"
	pushd "$final_path"
		sudo -u $app python3 -m venv "$final_path/venv"
		sudo -u $app $final_path/venv/bin/pip --cache-dir "$final_path/.cache/pip" install -U wheel pip setuptools 2>&1
		while read requirement ; do
			if [ ! -z "$requirement" ] && [[ ! "$requirement" =~ ^'#'.*  ]]; then
				sudo -u $app PYTHONUNBUFFERED=1 "$final_path/venv/bin/pip" --cache-dir "$final_path/.cache/pip" install "$requirement" 2>&1
			fi
		done < "$final_path/requirements.txt"
		sudo -u $app $final_path/venv/bin/pip --cache-dir "$final_path/.cache/pip" install -U django-auth-ldap 2>&1
		sudo -u $app mkdir -p "$final_path/srv"
		sudo -u $app cp -rT "$final_path/photonix" "$final_path/srv/photonix"
	popd
	pushd "$final_path/srv"
		sudo -u $app $final_path/venv/bin/python "$final_path/srv/photonix/manage.py" collectstatic --noinput --link 2>&1
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

	chown -R $app:$app "$final_path"
	sudo -u $app touch "$final_path/.yarnrc"
	sudo -u $app mkdir -p "$final_path/srv/ui"
	pushd "$final_path"
		sudo -u $app cp -T "$final_path/ui/package.json" "$final_path/srv/ui/package.json"
		sudo -u $app cp -T "$final_path/ui/yarn.lock" "$final_path/srv/ui/yarn.lock"
	popd

	pushd "$final_path/srv/ui"
		sudo -u $app env "PATH=$node_path" yarn --cache-folder $final_path/yarn-cache --use-yarnrc $final_path/.yarnrc install 2>&1
		sudo -u $app cp -rT "$final_path/ui/public" "$final_path/srv/ui/public"
		sudo -u $app cp -rT "$final_path/ui/src" "$final_path/srv/ui/src"
		sudo -u $app env "PATH=$node_path" yarn --cache-folder $final_path/yarn-cache --use-yarnrc $final_path/.yarnrc build 2>&1
	popd

	sudo -u $app cp -rT "$final_path/ui/public" "$final_path/srv/ui/public"

	set_permissions
}

function add_envfile {
	secret_key=$(ynh_app_setting_get --app=$app --key=secret_key)

	if [ -z $secret_key ]; then
		secret_key=$(ynh_string_random -l 64)
		ynh_app_setting_set --app=$app --key=secret_key --value=$secret_key
	fi

	ynh_add_config --template="photonix.env" --destination="$final_path/photonix.env"

	set_permissions
}

function apply_db_migrations {
	pushd "$final_path/srv/photonix" || ynh_die
		sudo -u $app bash -c "
			source \"$final_path/venv/bin/activate\"
			set -a
			source \"$final_path/photonix.env\"
			python \"$final_path/photonix/manage.py\" makemigrations
			python \"$final_path/photonix/manage.py\" migrate"
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
	final_path="$(ynh_app_setting_get --app=$app --key=final_path)"
	data_path="$(ynh_app_setting_get --app=$app --key=data_path)"
	domain=$(ynh_app_setting_get --app=$app --key=domain)
	path_url=$(ynh_app_setting_get --app=$app --key=path)
	db_name=$(ynh_app_setting_get --app=$app --key=db_name)
	db_user=$db_name
	db_pwd=$(ynh_app_setting_get --app=$app --key=psqlpwd)
	admin=$(ynh_app_setting_get --app=$app --key=admin)
	port=$(ynh_app_setting_get --app=$app --key=port)
	classification_color_enabled=$(ynh_app_setting_get --app=$app --key=classification_color_enabled)
	classification_location_enabled=$(ynh_app_setting_get --app=$app --key=classification_location_enabled)
	classification_face_enabled=$(ynh_app_setting_get --app=$app --key=classification_face_enabled)
	classification_style_enabled=$(ynh_app_setting_get --app=$app --key=classification_style_enabled)
	classification_object_enabled=$(ynh_app_setting_get --app=$app --key=classification_object_enabled)
}

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
