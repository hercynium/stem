#!/usr/bin/env perl

use strict ;
use warnings ;

use Config ;
use File::Spec ;
use BuildStem ;
use Data::Dumper ;

# I wonder if I should add the ability to put the Docs and Design etc
# directories in apropriate spots, like 
# /usr/local/share/stem (site) or /usr/share/stem (vendor)

my %requires ;

my $version_from = File::Spec->catfile( File::Spec->curdir, 'lib', 'Stem.pm' );

my $build = BuildStem->new(
#my $build = $class->new(
	module_name		=> 'Stem',
	dist_version_from	=> $version_from,
	requires		=> \%requires,
	dist_abstract 		=> 'ABSTRACT GOES HERE',
	license			=> 'gpl',
	dynamic_config		=> 1,
	recursive_test_files	=> 1,
	create_makefile_pl	=> 'passthrough'
);



$build->is_unixish() || die "Stem currently only installs properly on *nix-like platforms.\n";

### this will come in handy for some refactoring...
## $build->config( 'install_base' )

print <<'EOT';

Stem comes with a utility called 'run_stem' which takes care of things
like initalizing Stem with a configuration file and controlling it's
operation via various parameters you can pass in as environment
variables or command line arguments.

Stem configuration files are used to create and initialize Stem Cells
(objects). run_stem can search a path list for config files, so you
can set that list of directories here.

Note that you can easily override this path with either a shell environment
variable or on the command line of run_stem. See the documentation on
run_stem for how so do this.

The last directory in the list is where the standard and demo Stem
configuration files will be installed.

EOT

my $conf_path = $build->prompt(
	"Please enter a list of directory paths separated by ':'\n",
	'.:~/.stem/conf:/usr/local/stem/conf'
);
$build->config_data(conf_path => $conf_path);



print "\n\nChecking to see if you have a good C compiler...\n\n" ;
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
	my $build_ssfe = $build->y_n("Do you want to  build ssfe?\n", 'y');
	$build->config_data(build_ssfe => $build_ssfe);
}


print <<'EOT';

Stem comes with a variety of demos to show how to get started and do some
basic things. If you wish, they can be configured to run locally out of the 
demo/ directory.

EOT
my $build_demos = $build->y_n("\nDo you want to build the demos?\n",'y');
$build->config_data(build_demos => $build_demos);
if ( $build_demos ) {

	# Check for telnet
	my $telnet_path = $build->find_binary( 'telnet' ) || '' ;
	while ( ! -x $telnet_path && ! $build->_is_unattended() ) {
		print <<'EOT';

telnet was not found on this system. you can't run the demo programs
without telnet.  Make sure you enter a valid path to telnet or some other
terminal emulator.

NOTE: If you don't have an telnet, you can still run the demo scripts
by hand. Run a *_demo script and see what telnet commands it
issues. The run those telnet commands using your telnet or another
similar program.

EOT
		$telnet_path = $build->prompt(
			  "Enter the path to telnet "
			. "(or another compatible telnet client)",
            '/usr/bin/telnet'
		) ;
	}
	$build->config_data( telnet_path => $telnet_path ) ;


	# Check for xterm
	my $xterm_path = $build->find_binary( 'xterm' ) || '' ;
	while ( ! -x $xterm_path && ! $build->_is_unattended() ) {
		print <<'EOT';


xterm was not found on this system. you can't run the demo programs
without xterm.  Make sure you enter a valid path to xterm or some other
terminal emulator.

NOTE: If you don't have an xterm, you can still run the demo scripts
by hand. Run a *_demo script and see what commands it issues. Take the
part after the -e and run that command in its own terminal window.

EOT
		$xterm_path = $build->prompt(
			  "Enter the path to xterm "
			. "(or another compatible terminal emulator)",
            '/usr/bin/xterm'
		) ;
}
	$build->config_data( xterm_path => $xterm_path ) ;

}



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
