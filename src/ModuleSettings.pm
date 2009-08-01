#    Copyright (c) 2007 Erland Isaksson (erland_i@hotmail.com)
# 
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
package Plugins::CustomScan::ModuleSettings;

use strict;
use base qw(Plugins::CustomScan::BaseSettings);

use File::Basename;
use File::Next;

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Misc;
use Slim::Utils::Strings;

my $prefs = preferences('plugin.customscan');
my $log   = logger('plugin.customscan');

my $plugin; # reference to main plugin
my $modules;

sub new {
	my $class = shift;
	$plugin   = shift;

	$class->SUPER::new($plugin);
}

sub name {
	return 'PLUGIN_CUSTOMSCAN_MODULESETTINGS';
}

sub page {
	return 'plugins/CustomScan/settings/modulesettings.html';
}

sub currentPage {
	my ($class, $client, $params) = @_;
	return Slim::Utils::Strings::string(name())." ".$params->{'pluginCustomScanModule'}->{'name'};
}

sub pages {
	my ($class, $client, $params) = @_;
	my @pages = ();
	if(!defined($modules)) {
		$modules = Plugins::CustomScan::Plugin::getPluginModules();
	}
	for my $key (keys %$modules) {
		my $module = $modules->{$key};
		my %page = (
			'name' => Slim::Utils::Strings::string(name())." ".$module->{'name'},
			'page' => page()."?module=".$key,
		);
		push @pages,\%page;
	}
	return \@pages;
}

sub handler {
	my ($class, $client, $params) = @_;

	if(defined($params->{'saveSettings'})) {
		saveHandler($class, $client, $params);
	}
	$modules = Plugins::CustomScan::Plugin::getPluginModules();
	my $module = $modules->{$params->{'module'}};

	$params->{'pluginCustomScanModule'} = $module;
	$params->{'pluginCustomScanModuleId'} = $params->{'module'};
	$params->{'pluginCustomScanModuleActive'} = $module->{'active'};
	$params->{'pluginCustomScanModuleEnabled'} = $module->{'enabled'};
	$params->{'pluginCustomScanModuleOrder'} = $module->{'order'};
	$params->{'pluginCustomScanModuleName'} = $module->{'name'};
	$params->{'pluginCustomScanModuleDescription'} = $module->{'description'};
	$params->{'pluginCustomScanModuleDevelopedBy'} = $module->{'developedBy'} if defined($module->{'developedBy'});
	$params->{'pluginCustomScanModuleDevelopedByLink'} = $module->{'developedByLink'} if defined($module->{'developedByLink'});
	my @properties = ();
	my $moduleProperties = $module->{'properties'};
	for my $property (@$moduleProperties) {
		my %p = (
			'id' => $property->{'id'},
			'name' => $property->{'name'},
			'description' => $property->{'description'},
			'type' => $property->{'type'}
		);
		my $value = Plugins::CustomScan::Plugin::getCustomScanProperty($property->{'id'});
		if(!defined($value)) {
			$value = $property->{'value'};
		}
		$p{'value'} = $value;
		if(defined($property->{'values'})) {
			my $values = $property->{'values'};
			$p{'values'} = $values;
			my @selectedValuesArray = ();
			if(defined($p{'value'})) {
				@selectedValuesArray = split(/,/,$p{'value'});
			}
			for my $value (@$values) {
				delete $value->{'selected'};
				for my $selectedValue (@selectedValuesArray) {
					if($value->{'id'} eq $selectedValue) {
						$value->{'selected'} = 1;
					}
				}
			}
		}
		push @properties,\%p;
	}	
	$params->{'pluginCustomScanModuleProperties'} = \@properties;

	return $class->SUPER::handler($client, $params);
}

sub saveHandler {
	my ($class, $client, $params) = @_;

	my $modules = Plugins::CustomScan::Plugin::getPluginModules();

	my $module = $modules->{$params->{'module'}};
	
	my $moduleProperties = $module->{'properties'};

	my %errorItems = ();
	foreach my $property (@$moduleProperties) {
		my $propertyid = "property_".$property->{'id'};
		if($params->{$propertyid} && $property->{'type'} !~ /.*multiplelist$/) {
			my $value = $params->{$propertyid};
			if(defined($property->{'validate'})) {
				eval { $value = &{$property->{'validate'}}($value)};
				if ($@) {
					$log->error("CustomScan: Failed to call validate metod on ".$property->{'id'}.": $@\n");
				}
			}
			if(defined($value)) {
				Plugins::CustomScan::Plugin::setCustomScanProperty($property->{'id'},$value);
			}else {
				$errorItems{$property->{'id'}} = 1;
			}
		}elsif($property->{'type'} eq 'checkbox') {
			Plugins::CustomScan::Plugin::setCustomScanProperty($property->{'id'},0);
		}elsif($property->{'type'} eq 'checkboxes') {
			my $values = getCheckBoxesQueryParameter($params, 'property_'.$property->{'id'});
			my $valuesString = '';
			for my $value (keys %$values) {
				if($valuesString ne '') {
					$valuesString .= ',';
				}
				$valuesString .= $value;
			}
			Plugins::CustomScan::Plugin::setCustomScanProperty($property->{'id'},$valuesString);
		}elsif($property->{'type'} =~ /.*multiplelist$/) {
			my $values = getMultipleListQueryParameter($params, 'property_'.$property->{'id'});
			my $valuesString = '';
			for my $value (keys %$values) {
				if($valuesString ne '') {
					$valuesString .= ',';
				}
				$valuesString .= $value;
			}
			Plugins::CustomScan::Plugin::setCustomScanProperty($property->{'id'},$valuesString);
		}else {
			Plugins::CustomScan::Plugin::setCustomScanProperty($property->{'id'},'');
		}
	}
	if($params->{'moduleenabled'}) {
		$module->{'enabled'} = 1;
		$prefs->set('module_'.$module->{'id'}.'_enabled',1);
	}else {
		$module->{'enabled'} = 0;
		$prefs->set('module_'.$module->{'id'}.'_enabled',0);
	}
	if($params->{'moduleactive'}) {
		$module->{'active'} = 1;
		$prefs->set('module_'.$module->{'id'}.'_active',1);
	}else {
		$module->{'active'} = 0;
		$prefs->set('module_'.$module->{'id'}.'_active',0);
	}
	if($params->{'moduleorder'}) {
		$module->{'order'} = $params->{'moduleorder'};
		$prefs->set('module_'.$module->{'id'}.'_order',$params->{'moduleorder'});
	}
	if(scalar(keys %errorItems)>0) {
		$params->{'pluginCustomScanErrorItems'} = \%errorItems;
	}
}

sub getCheckBoxesQueryParameter {
	my $params = shift;
	my $parameter = shift;

	my %result = ();
	foreach my $key (keys %$params) {
		my $pattern = '^'.$parameter.'_(.*)';
		if ($key =~ /$pattern/) {
			my $id  = unescape($1);
			if ($id ne '*' && $id ne '') {
				$id = Slim::Utils::Unicode::utf8on($id);
				$id = Slim::Utils::Unicode::utf8encode_locale($id);
			}
			$result{$id} = 1;
		}
	}
	return \%result;
}

sub getMultipleListQueryParameter {
	my $params = shift;
	my $parameter = shift;

	my $query = $params->{url_query};
	my %result = ();
	if($query) {
		foreach my $param (split /\&/, $query) {
			if ($param =~ /([^=]+)=(.*)/) {
				my $name  = unescape($1);
				my $value = unescape($2);
				if($name eq $parameter) {
					# We need to turn perl's internal
					# representation of the unescaped
					# UTF-8 string into a "real" UTF-8
					# string with the appropriate magic set.
					if ($value ne '*' && $value ne '') {
						$value = Slim::Utils::Unicode::utf8on($value);
						$value = Slim::Utils::Unicode::utf8encode_locale($value);
					}
					$result{$value} = 1;
				}
			}
		}
	}
	return \%result;
}

# don't use the external one because it doesn't know about the difference
# between a param and not...
#*unescape = \&URI::Escape::unescape;
sub unescape {
        my $in      = shift;
        my $isParam = shift;

        $in =~ s/\+/ /g if $isParam;
        $in =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

        return $in;
}
		
1;
