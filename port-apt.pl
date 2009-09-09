#!/usr/bin/perl

use strict;
use warnings;

my $packages = "@ARGV" || 'outdated';
open(my $fh, '-|', "port deps $packages") || die "Can't open: $!";

my %ports;
my $port;
my $isdep;

while (<$fh>) {

#Full Name: git-core @1.6.4.2+doc+gitweb+svn
#Runtime Dependencies: rsync, perl5, p5-error, subversion, p5-libwww-perl, p5-svn-simple, p5-term-readkey
#Library Dependencies: curl, zlib, openssl, expat, libiconv
#--
#Full Name: libiconv @1.13
#Build Dependencies:   gperf

	if (/^Full Name: (.*?) /) {
		$port = $1;
		$ports{$port} = {};
	} elsif (/^(Runtime|Library|Build) Dependencies: (.*?)$/) {
		my $deps = $2;
		foreach my $dep (split /, /, $deps) {
			$ports{$port}{$dep} = 1;
		}
	}
}

dump_ports();

my $changed = 1;
my $level = 2;
while ($changed) {
	$changed = 0;
	foreach my $p (keys %ports) {
		foreach (keys %{$ports{$p}}) {
			foreach my $derived (map { $ports{$_} ? keys %{$ports{$_}} : () } keys %{$ports{$p}}) {
				if ($ports{$p}{$derived}) {
					next;
				}
				$changed = 1;
				$ports{$p}{$derived} = $level;
			}
		}
	}
	$level++;
	dump_ports();
}

my @ports = sort {
	if (!$ports{$a}{$b} && $ports{$b}{$a}) {
		-1;
	} elsif ($ports{$a}{$b} && !$ports{$b}{$a}) {
		1;
	} elsif (!$ports{$a}{$b} && !$ports{$b}{$a}) {
		keys %{$ports{$a}} <=> keys %{$ports{$b}};
	} else {
	print "$a<=>$b: $ports{$b}{$a} $ports{$a}{$b} \n";
	$ports{$b}{$a} <=> $ports{$a}{$b}
		        ||
		    $a cmp $b;
	}
} keys %ports;

print "@ports\n";

sub dump_ports {
	return;
	print "\n";
	foreach my $p (keys %ports) {
		print "$p\n";
		foreach (keys %{$ports{$p}}) {
			print "\t$_\t$ports{$p}{$_}\n";
		}
	}
}
