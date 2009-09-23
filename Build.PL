#!/usr/bin/env perl

use strict ;
use warnings ;

use Config ;
use File::Spec ;
use Data::Dumper ;

use BuildStem ;

my $version_from = File::Spec->catfile( 
    File::Spec->curdir, 'lib', 'Stem.pm' 
);

my $build = BuildStem->new(
    module_name		 => 'Stem',
    dist_version_from	 => $version_from,
    requires		 => {
      YAML        => 0,
    },
    dist_abstract	 => 
        'An asynchronous message passing framework for Perl',
    license		 => 'gpl',
    dynamic_config	 => 1,
    recursive_test_files => 1,
    needs_compiler       => 0,
    recommends           => {
	DBI    => 0,
        Event  => 0,
    },
    create_makefile_pl	 => 'passthrough'
);



$build->is_unixish() or 
  die "Stem currently only installs properly on *nix-like platforms.\n";


### ask about the config path and where to install bundled config files

print <<'EOT';

Stem configuration files are used to create and initialize Stem Cells.
An included program called 'run_stem' will search a default path for 
a specified config file and use it to get everything going. You can see
this in action if you check out Stem's demo scripts.

Note that you can easily override this path with either a shell environment
variable or a command line agrument. See the documentation on run_stem for 
how to do this.

EOT

$build->config_data( 
    conf_path => scalar $build->prompt(
        "Please enter a list of directory paths separated by ':'\n",
	'.:~/.stem/conf:/usr/local/stem/conf'
    )
);


print <<'EOT';

Where would you like to install the config files bundled with Stem?
If you specify a directory not already in the path above, it will be
appended. If this directory does not exist, it will be created.

EOT

$build->config_data( 
    conf_dir => scalar $build->prompt(
        "Please enter a directory path:\n",
	'/usr/local/stem/conf'
    )
);

### add the conf_dir to the conf_path, if necessary
{
    my $conf_path = $build->config_data( 'conf_path' );
    my $conf_dir  = $build->config_data( 'conf_dir' );
    if ( $conf_path =~ /(^|:)\Q$conf_dir\E(:|$)/ ) {
        $build->config_data( conf_path => "$conf_path:$conf_dir" );
    }
}



### ask about building the demo scripts
print <<'EOT';

Stem comes with a variety of demos to show how to get started and do some
basic things. If you wish to try them they will be available in the demo/
directory after you run ./Build. In any case, they will not be installed 
to the system, even after you install the rest of Stem.

EOT

$build->config_data(
    build_demos => scalar $build->y_n(
        "Do you want to build the demos?\n", 'y'
    )
);


if ( $build->config_data( 'build_demos' ) ) {


	### Try to find telnet
	my $telnet_path = $build->find_binary( 'telnet' ) || '' ;
	while ( ! -x $telnet_path && ! $build->_is_unattended() ) {
		print <<'EOT';

telnet was not found on this system. the demo programs won't run properly
without telnet. Please enter a valid path to telnet, or a single <space> 
to give up trying.

EOT
		$telnet_path = $build->prompt(
			  "Enter the path to telnet "
			. "(or another compatible telnet client)",
					      '/usr/bin/telnet'
		) ;
		last if $telnet_path =~ s/^\w+$//;
	}
	$build->config_data( telnet_path => $telnet_path || undef ) ;




	# Try to find xterm
	my $xterm_path = $build->find_binary( 'xterm' ) || '' ;
	while ( ! -x $xterm_path && ! $build->_is_unattended() ) {
	    print <<'EOT';

xterm was not found on this system. the demo programs won't run properly
without xterm.  Please enter a valid path to xterm or a single <space> to
give up trying.

EOT
	    $xterm_path = $build->prompt(
	        "Enter the path to xterm "
	      . "(or another compatible terminal emulator)",
	      '/usr/bin/xterm'
	    ) ;
	    last if $xterm_path =~ s/^\w+$//;
	}
	$build->config_data( xterm_path => $xterm_path || undef ) ;


    ### Only build ssfe if we have a working C compiler
    if ( $build->have_c_compiler() ) {
        print <<'EOT';

ssfe (Split Screen Front End) is a compiled program optionally used by
the Stem demonstration scripts that provides a full screen interface
with command line editing and history. It is not required to run Stem
but it makes the demonstrations easier to work with and they look much
nicer. To use ssfe add the '-s' option when you run any demonstration
script. You can also use ssfe for your own programs. If you build ssfe
it will be installed in the demo/ directory. You may copy it to a place
in your $PATH is you wish.

EOT
	$build->config_data(
	    build_ssfe => scalar $build->y_n(
                "Do you want to build ssfe for the demos?\n", 'y'
            )
        );
    }
}




### NOTE: find out whether or not each of the following 
### config_data settings are actually being *used* for anything

my $script_dest = $build->install_destination('script') ;
my $run_stem_path = File::Spec->catfile( $script_dest, 'run_stem' ) ;
$build->config_data( run_stem_path => $run_stem_path ) ;




my $bin_path = $build->install_destination('bin') ;
$build->config_data( bin_path => $bin_path ) ;

$build->config_data( perl_path => $build->config( 'perlpath' ) ) ;

# Several different prefixes... which one to use??
#$build->config_data( prefix => $build->prefix() ) ;
$build->config_data( prefix => $build->config( 'install_base' ) ) ;


$build->config_data( config_done => 1 ) ;


#print Dumper \%{ $build->config_data() };


$build->create_build_script() ;

exit ;

1 ;
