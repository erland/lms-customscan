# 			MixedTagMixHandler module
#
#    Copyright (c) 2006 Erland Isaksson (erland_i@hotmail.com)
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

package Plugins::CustomScan::MixedTagSQLPlayListHandler;

use strict;
use DBI qw(:sql_types);

sub new {
	my $class = shift;
	my $parameters = shift;

	my $self = {};

	bless $self,$class;
	return $self;
}

sub isInterfaceSupported {
	my $self = shift;
	my $mixHandler = shift;
	my $client = shift;
	my $mix = shift;
	my $interfaceType = shift;

	if($interfaceType eq 'web') {
		return 1;
	}
	return 0;	
}

sub executeMix {
	my $self = shift;
	my $mixHandler = shift;
	my $client = shift;
	my $mix = shift;
	my $keywords = shift;
	my $addOnly = shift;
	my $interfaceType = shift;
}

sub checkMix {
	my $self = shift;
	my $mixHandler = shift;
	my $client = shift;
	my $mix = shift;
	my $keywords = shift;

	my $enabled = 0;
	for my $keyword (keys %$keywords) {
		if($keyword =~ /^level(\d+)/) {
			$enabled=1;
		}
	}
	return $enabled;
}

sub getMixData {
	my $self = shift;
	my $mixHandler = shift;
	my $client = shift;
	my $mix = shift;
	my $keywords = shift;
	my $interfaceType = shift;
	my $parameter = shift;
	
	if($parameter =~ /^mixurl/) {
		my $url = 'plugins/CustomScan/newsqlplaylist_redirect.html?';
		if(grep { /^level(\d+)$/ } keys %$keywords) {
			$url .= "type=mixedtag";
			my $i = 1;
			my $j = 1;
			while(exists $keywords->{'level'.$i}) {
				my $tagname = $keywords->{'level'.$i++};
				my $tagvalue = $keywords->{'level'.$i++.'_'.$tagname};

				if(defined($tagname) && defined($tagvalue))  {
					$url .= '&mixedtag'.($j).'name='.$tagname;
					$url .= '&mixedtag'.($j++).'value='.$tagvalue;
				}
			}
			if($j>1) {
				return $url;
			}
		}
	}
	return $mix->{$parameter};
}

1;

__END__
