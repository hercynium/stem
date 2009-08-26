#!/usr/bin/env perl

use strict ;
use warnings ;
use Test::More tests => 2;
use Test::Exception;

use_ok( 'Stem' );

my @config = (
    {	class 	=> 	'Foobar', 			},
	{	class	=>	'Stem::Console', 	},
) ;


lives_ok( sub { Stem::Conf::configure( \@config ) }, 'load config from data structure' );

package Foobar ;

sub foobar_cmd { return "FOOBAR!!!\n" }


