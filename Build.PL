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


print <<'EOT';

Building Stem

This script will ask you various questions in order to properly
configure, build and install Stem on your system.  Whenever a question
is asked, the default answer will be shown inside [brackets].
Pressing enter will accept the default answer. If a choice needs to be
made from a list of values, that list will be inside (parentheses).

If you have already configured Stem in a previous build, you can put
use_defaults=1 on the Build command line and you won't be prompted for
any answers and the previous settings will be used.

If you want to force a new build, run Build clean.

----------------------------------------------------------------------------

EOT



print <<'EOT';

Stem configuration files are used to create and initialize Stem Cells
(objects). Stem needs to know the list of directories to search to
find its configurations files.

Note that the default has a single absolute path. You can test Stem
configurations easily setting this path when executing run_stem. You
can override or modify the path time with either a shell environment
variable or on the command line of run_stem. See the documentation on
run_stem for how so do this.

The first directory in the list is where the standard Stem
configuration files will be installed.

Enter a list of absolute directory paths separated by ':'.

EOT

my $conf_path = $build->prompt(
	"What directories do you want Stem to search for configuration files?\n",
	'.:./conf:~/.stem/conf:/usr/local/stem/conf'
);
$build->config_data(conf_path => $conf_path);






=begin comment

print "\n\nChecking to see if you have a good C compiler...\n\n" ;
if ( $build->have_c_compiler() ) {
	print <<'EOT';
	
	
ssfe (Split Screen Front End) is a compiled program optionally used by
the Stem demonstration scripts that provides a full screen interface
with command line editing and history. It is not required to run Stem
but it makes the demonstrations easier to work with and they look much
nicer. To use ssfe add the '-s' option when you run any demonstration
script. You can also use ssfe for your own programs.  Install ssfe in
some place in your $PATH ($conf->{'bin_path'} is where Stem executables
are being installed) so it can be used by the demo scripts. The ssfe
install script will do this for you or you can do it manually after
building it.

EOT
	my $install_ssfe = $build->y_n("Do you want to install ssfe?\n", 'y');
	$build->config_data(install_ssfe => $install_ssfe);
	if ( $install_ssfe ) {

		# Do horrible, nasty things.
		# This really should be done with a proper makefile.

	}
}

=cut





print <<'EOT';

Stem comes with a variety of demos to show how to get started and do some 
basic things.

EOT
my $install_demos = $build->y_n("\nDo you want to install the demos?\n",'n');
$build->config_data( install_demos => $install_demos ) ;
$build->config_data( build_demos => $install_demos ) ;
if ( $install_demos ) {

	my $demo_dir = $build->prompt(
		"\nWhere do you want to install the demo scripts?\n",
		'/usr/local/stem/demo'
	);
	$build->config_data(demo_dir => $demo_dir);
	$build->install_path()->{demo} ||= $demo_dir;



	my $demo_conf_dir = $build->prompt(
		"\nWhere do you want to install the demo config files?\n",
		'/usr/local/stem/conf'
	);
	$build->config_data(demo_conf_dir => $demo_conf_dir);
	$build->install_path()->{conf} ||= $demo_conf_dir;
	$build->add_build_element('conf');

	my $cur_conf_path = $build->config_data('conf_path') ;
	my $new_conf_path = $cur_conf_path =~ /(^|:)$demo_conf_dir(:|$)/ ?
		$cur_conf_path : "$cur_conf_path:$demo_conf_dir" ;
	$build->config_data( conf_path => $new_conf_path ) ;


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
