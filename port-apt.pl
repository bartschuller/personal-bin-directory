#!/usr/bin/perl

use strict;
use warnings;

my $packages = "@ARGV" || 'outdated';
open(my $fh, '-|', "port deps $packages") || die "Can't open: $!";

my %ports;
my $port;
my $isdep;

while (<$fh>) {
	print;
	if (/^(.*?) has (.*?) dependencies/) {
		$port = $1;
		$isdep = $2 =~ /library|build/ ? 1 : 0;
		$ports{$port} = {};
	} elsif (/^\s+(.*?)$/) {
		my $dep = $1;
		$ports{$port}{$dep} = 1;
	}
}

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
