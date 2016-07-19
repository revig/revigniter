function create_menu(basepath)
{
	var base = (basepath === 'null') ? '' : basepath;

	document.getElementById('panelContent').innerHTML='<div class="row">' +
			'<div class="col-sm-3">' +
			'<ul id="list-1" class="list">' +
			'<li class="header">revIgniter</li>' +
			'<li class="item"><a href="'+base+'index.html">User Guide Home</a></li>' +
			'<li class="item"><a href="'+base+'toc.html">Table of Contents Page</a></li>' +
			
		 	'<li class="header">Basic Info</li>' +
		 	'<li class="item"><a href="'+base+'general/requirements.html">Server Requirements</a></li>' +
			'<li class="item"><a href="'+base+'license.html">License Agreement</a></li>' +
			'<li class="item"><a href="'+base+'changelog.html">Change Log</a></li>' +
			'<li class="item"><a href="'+base+'general/credits.html">Credits</a></li>' +
			
			'<li class="header">Installation</li>' +
		 	'<li class="item"><a href="'+base+'installation/downloads.html">Downloading revIgniter</a></li>' +
		 	'<li class="item"><a href="'+base+'installation/index.html">Installation Instructions</a></li>' +
		 	'<li class="item"><a href="'+base+'installation/upgrading.html">Upgrading from a Previous Version</a></li>' +
		 	'<li class="item"><a href="'+base+'installation/troubleshooting.html">Troubleshooting</a></li>' +
		 	
		 	'<li class="header">Introduction</li>' +
		 	'<li class="item"><a href="'+base+'overview/getting_started.html">Getting Started</a></li>' +
		 	'<li class="item"><a href="'+base+'overview/at_a_glance.html">revIgniter at a Glance</a></li>' +
		 	'<li class="item"><a href="'+base+'overview/cheatsheets.html">revIgniter Cheatsheets</a></li>' +
		 	'<li class="item"><a href="'+base+'overview/features.html">Supported Features</a></li>' +
		 	'<li class="item"><a href="'+base+'overview/appflow.html">Application Flow Chart</a></li>' +
		 	'<li class="item"><a href="'+base+'overview/mvc.html">Model-View-Controller</a></li>' +
			'<li class="item"><a href="'+base+'overview/hmvc.html">HMVC - Extending MVC</a></li>' +
		 	'<li class="item"><a href="'+base+'overview/goals.html">Architectural Goals</a></li>' +
		'</ul>' +
		'</div>' +
			
		'<div class="col-sm-3">' +
		'<ul id="list-2" class="list">' +
		 	'<li class="header">General Topics</li>' +
		 	'<li class="item"><a href="'+base+'general/urls.html">revIgniter URLs</a></li>' +
			'<li class="item"><a href="'+base+'general/controllers.html">Controllers</a></li>' +
			'<li class="item"><a href="'+base+'general/reserved_names.html">Reserved Names</a></li>' +
			'<li class="item"><a href="'+base+'general/views.html">Views</a></li>' +
			'<li class="item"><a href="'+base+'general/models.html">Models</a></li>' +
			'<li class="item"><a href="'+base+'general/helpers.html">Helpers</a></li>' +
			'<li class="item"><a href="'+base+'general/plugins.html">Plugins</a></li>' +
			'<li class="item"><a href="'+base+'general/libraries.html">Using revIgniter Libraries</a></li>' +
			'<li class="item"><a href="'+base+'general/creating_libraries.html">Creating Your Own Libraries</a></li>' +
			'<li class="item"><a href="'+base+'general/core_libraries.html">Creating Core Libraries</a></li>' +
			'<li class="item"><a href="'+base+'general/using_stacks.html">Using Stacks</a></li>' +
			'<li class="item"><a href="'+base+'general/hooks.html">Hooks - Extending the Core</a></li>' +
			'<li class="item"><a href="'+base+'general/autoloader.html">Auto-loading Resources</a></li>' +
			'<li class="item"><a href="'+base+'general/common_handlers.html">Common Handlers</a></li>' +
			'<li class="item"><a href="'+base+'general/scaffolding.html">Scaffolding</a></li>' +
			'<li class="item"><a href="'+base+'general/routing.html">URI Routing</a></li>' +
			'<li class="item"><a href="'+base+'general/modules.html">Modules</a></li>' +
			'<li class="item"><a href="'+base+'general/extensions.html">Extensions</a></li>' +
			'<li class="item"><a href="'+base+'general/errors.html">Error Handling</a></li>' +
			'<li class="item"><a href="'+base+'general/caching.html">Caching</a></li>' +
			'<li class="item"><a href="'+base+'general/profiling.html">Profiling Your Application</a></li>' +
			'<li class="item"><a href="'+base+'general/managing_apps.html">Managing Applications</a></li>' +
			'<li class="item"><a href="'+base+'general/security.html">Security</a></li>' +
			
			'<li class="header">Tutorials</li>' +
		 	'<li class="item"><a href="'+base+'tutorials/chat.html">Simple Chat Application</a></li>' +
		'</ul>' +
		'</div>' +
		
		'<div class="col-sm-3">' +
		'<ul id="list-3" class="list">' +
		 	'<li class="header">Library Reference</li>' +
			'<li class="item"><a href="'+base+'libraries/authentication.html">Authentication Library</a></li>' +
		 	'<li class="item"><a href="'+base+'libraries/benchmark.html">Benchmarking Library</a></li>' +
		 	'<li class="item"><a href="'+base+'libraries/calendar.html">Calendaring Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/captcha.html">Captcha Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/config.html">Config Library</a></li>' +
			'<li class="item"><a href="'+base+'database/index.html">Database Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/email.html">Email Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/encryption.html">Encryption Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/file_uploading.html">File Uploading Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/form_validation.html">Form Validation Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/table.html">HTML Table Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/image_lib.html">Image Manipulation Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/input.html">Input and Security Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/jquery.html">jQuery Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/language.html">Language Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/loader.html">Loader Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/modules.html">Modules Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/output.html">Output Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/pagination.html">Pagination Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/sessions.html">Session Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/trackback.html">Trackback Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/uri.html">URI Library</a></li>' +
			'<li class="item"><a href="'+base+'libraries/user_agent.html">User Agent Library</a></li>' +
		'</ul>' +
		'</div>' +
		
		'<div class="col-sm-3">' +	
		'<ul id="list-4" class="list">' +
		 	'<li class="header">Helper Reference</li>' +
		 	'<li class="item"><a href="'+base+'helpers/array_helper.html">Array Helper</a></li>' +
		 	'<li class="item"><a href="'+base+'helpers/asset_helper.html">Asset Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/cookie_helper.html">Cookie Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/date_helper.html">Date Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/download_helper.html">Download Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/email_helper.html">Email Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/file_helper.html">File Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/form_helper.html">Form Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/formmail_helper.html">Form-Mail Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/html_helper.html">HTML Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/jwt_helper.html">JWT Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/language_helper.html">Language Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/string_helper.html">String Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/url_helper.html">URL Helper</a></li>' +
			'<li class="item"><a href="'+base+'helpers/xml_helper.html">XML Helper</a></li>' +
			
			'<li class="header">Plugin Reference</li>' +
			'<li class="item"><a href="'+base+'plugins/galleria_plugin.html">Galleria Plugin</a></li>' +
			'<li class="item"><a href="'+base+'plugins/markdown_plugin.html">Markdown Plugin</a></li>' +
		 	'<li class="item"><a href="'+base+'plugins/querytojson_plugin.html">QueryToJSON Plugin</a></li>' +
		 	'<li class="item"><a href="'+base+'plugins/queryvalues_plugin.html">QueryValues Plugin</a></li>' +
			'<li class="item"><a href="'+base+'plugins/sitelinks_plugin.html">SiteLinks Plugin</a></li>' +
		'</ul>' +
		'</div>' +
		'</div>';
		
}
