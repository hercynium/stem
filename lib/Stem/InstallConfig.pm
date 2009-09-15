package Stem::InstallConfig;

use strict;
use warnings;

use Stem::ConfigData;

our %Config = 
    map { $_ => Stem::ConfigData->config( $_ ) } 
    Stem::ConfigData->config_names();

our %__PACKAGE__ = %Config;

#use Data::Dumper; print Dumper \%Config, \%__PACKAGE__; exit;

1;
