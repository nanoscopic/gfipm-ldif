#!/usr/bin/perl -w

# generate_ldif.pl
# LDIF Change Generation Script For Registered GFIPM Namespace
# Copyright (C) 2014 David Helkowski
# License: CC BY-NC-ND 3.0, license.txt, http://creativecommons.org/licenses/by-nc-nd/3.0/
# https://github.com/nanoscopic/gfipm-ldif

# Notes:
#
# 2.16.840.1.113883.3.4327 is the registered root of "Carbon State" on the HL7 tree.
#     HL7.org provides the ability for any private business to register their own OID on their tree.
#     This was done so as to provide a permanent home for the GFIPM attributes that will not conflict with any existing OIDs.
#     At some point documentation on this will be put up at http://www.carbonstate.com/oid/gfipm
#
# The generated 99-user.ldif file should be "merged" with any existing 99-user.ldif file. If it is just
#     replaced outright it would erase whatever other custom attributes already exist in that file.
#
use strict;

my $oidroot = "2.16.840.1.113883.3.4327.1.2."; 
my $nameroot = "gfipm-user-";
my $mods = 1; # Whether to generate an ldif file to "apply" or lines to shove in 99-user.ldif ( if latter, set mods to 0 )

eval('use XML::Bare qw/xval forcearray/;');
my $xmod = 1;
if( $@ ) { $xmod = 0; }
eval('use Date::Format;');
my $dmod = 1;
if( $@ ) { $dmod = 0; }

my $mode = $ARGV[0];

my $shown = 0;
sub header {
    if( !$shown ) {
        print "LDIF Change Generation Script For Registered GFIPM Namespace\n";
        print "Copyright (C) 2014 David Helkowski\n";
        print "------------------------------------------------------------\n";
    }
    $shown = 1;
}
sub usage {
    header();
    print "Usage:\n";
    print "perl generate_ldif.pl ldif\n";
    print "perl generate_ldif.pl user\n";
    print "perl generate_ldif.pl map\n";
    print "perl generate_ldif.pl all\n";
    if( !$xmod || !$dmod ) {
        print "\n";
    }
    if( !$xmod ) {
        print STDERR "Error - XML::Bare Perl CPAN module is not installed. Please install it for this script to work properly\n";
    }
    if( !$dmod ) {
        print STDERR "Error - Date::Format Perl CPAN module is not installed. Please install it for this script to work properly\n";
    }
}

if( !$mode || !$xmod || !$dmod ) {
    usage();
    exit;
}

my $handle;
my %namehash;

if( $mode eq 'all' ) {
    runmode( 'ldif' );
    runmode( 'user' );
    runmode( 'map' );
}
else {
    runmode( $mode );
}

sub runmode {
    my $mode = shift;
    my $output_file = "";
    if( $mode eq 'ldif' ) {
        $mods = 1;
        $output_file = 'output/gfipm.ldif';
    }
    elsif( $mode eq 'user' ) {
        $mods = 0;
        $output_file = 'output/99-user.ldif';
    }
    elsif( $mode eq 'map' ) {
        $output_file = 'output/gfipm-map.txt';
    }
    else {
        usage();
        exit;
    }
    header();
    
    print "Generating $output_file\n";
    open( $handle, ">$output_file" );
    
    if( $mode eq 'user' ) {
        print $handle "dn: cn=schema
    objectClass: top
    objectClass: ldapSubentry
    objectClass: subschema
    cn: schema
    changetype: modify
    add: attributeTypes
    add: objectclasses";
    }
    
    my ( $ob, $xml ) = XML::Bare->new( file => 'gfipm.xml' );
    my $atts = forcearray( $xml->{'att'} );
    %namehash = ();
    for my $att ( @$atts ) {
        if( $mode eq 'map' ) { 
            printEquality( $att );
        }
        else { 
            addAttribute ( $att );
        }
        my $oid    = xval( $att->{'oid'} );
        my $name = $nameroot . xval( $att->{'name'} );
        $namehash{ $oid } = $name;
    }
    
    my $classes = forcearray( $xml->{'class'} );
    for my $class ( @$classes ) {
        if( $mode eq 'map' ) { 
            printClass( $class );
        }
        else { 
            addClass( $class );
        }
    }
    
    if( $mode eq 'user' ) {
        my $datetext = time2str( "%Y%m%d%H%M%SZ", time, "GMT" );
        print $handle "modifiersName: cn=Directory Manager,cn=Root DNs,cn=config
    modifyTimestamp: $datetext
    ";
    }
    
    close $handle;
}

sub printEquality {
    my $node = shift;
    
    my $oid = $oidroot . xval( $node->{'oid'} );
    my $name = xval( $node->{'name'} );
    print $handle "gfipm:2.0:user:$name=gfipm-user-$name\n";
}
sub printClass {
    
}

sub addAttribute {
    my $node = shift;
    
    my $oid = $oidroot . xval( $node->{'oid'} );
    my $name = $nameroot . xval( $node->{'name'} );
    if( $mods ) {
        print $handle "dn: cn=schema
changetype: modify
add: attributetypes\n";
    }
    print $handle "attributeTypes: ( $oid NAME '$name' EQUALITY caseIgnoreMatch ORDERING caseIgnoreOrderingMatch SUBSTR caseIgnoreSubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.15 USAGE userApplications )\n";
}
sub addClass {
    my $class = shift;
    
    my $oid = $oidroot . xval( $class->{'oid'} );
    my $name = xval( $class->{'name'} );
    my $may = xval( $class->{'may'} );
    $may =~ s/ //g;
    my @mays = split( ',', $may );
    my @maytexts;
    
    for my $amay ( @mays ) {
        my $aname = $namehash{ $amay };
        if( !$aname ) {
            print STDERR "Cannot find oid $amay in list of attributes\n";
        }
        else {
            push( @maytexts, $aname );
        }
    }
    my $maytext = join( ' $ ', @maytexts );
    
    if( $mods ) {
        print $handle "dn: cn=schema
changetype: modify
add: objectClasses\n";
    }
    print $handle "objectClasses: ( $oid NAME '$name' AUXILIARY MAY ( $maytext ) )\n";
}