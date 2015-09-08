package rpmperl;

use 5.00503;
use strict;

use vars qw/$VERSION @blacklist/;
use subs qw/rpmperl/;

# This is a list of available architectures (might need updating at some point).
my($archs) = "alpha|i.86|ia64|ppc|ppc64|x86_64|noarch";

use File::Basename;

$VERSION = '0.01';

sub init_blacklist
{
   my($blacklist_file) = @_;

   open(BLACKLIST, "$blacklist_file") or die "Cannot open $blacklist_file\n";
   chomp(@blacklist = <BLACKLIST>);
   close(BLACKLIST);
}

# return  1: A is newer than B
# return  0: A is equal to B
# return -1: B is newer than A
sub vercmp
{
   my ($verA, $verB) = @_;

   return 0 if ($verA eq $verB);
   return 1 if !$verB;

   while ( $verA and $verB )
   {
      use vars qw/$subA $subB $cmp/;

      if ( $verA =~ /^(\d+)/ )
      {
         ($subA = $verA) =~ s/^(\d+).*/$1/;
         ($subB = $verB) =~ s/^(\d+).*/$1/;
         $cmp = $subA <=> $subB;
      }
      else
      {
         ($subA = $verA) =~ s/^(\D+).*/$1/;
         ($subB = $verB) =~ s/^(\D+).*/$1/;
         $cmp = $subA cmp $subB;
      }

      return $cmp if $cmp;
      $verA =~ s/^$subA[-.]?//;
      $verB =~ s/^$subB[-.]?//;
   }

   return 0 if !$verA and !$verB;
   return 1 if !$verB;
   return -1 if !$verA;
}

# input rpm to check (either absolute file or string to be found in rpmdb)
# return array of what RPMs are required by input
sub required
{
   my($rpm_to_check) = @_;
   use vars qw/$query_opt @req @requires %required/;
   undef(@requires);

   # need to use -qp if $rpm_to_check is a file
   $query_opt = ( -f "$rpm_to_check" ) ? "-qpR" : "-qR";

   @req = `rpm $query_opt --nosignature $rpm_to_check | sed -e "s/\\((.*\\?)\\)\\?\\( [><]\\?=.*\\)\\?//g"`;
   while ( @req )
   {
      chomp(my($req) = pop(@req));
      $req =~ s/\s+//g;
      $req =~ s/\+/\\\+/g;
      next if grep (/$req/, @req);
      next if $req =~ /^rpmlib/;
      use vars qw/$prov/;

      if ( ! $required{$req} )
      {
         foreach $prov ( `rpm -q --whatprovides --queryformat '%{NAME}-%{VERSION}-%{RELEASE}\n' $req 2> /dev/null` )
         {
            next if $prov =~ /no package provides/;
            if ( $prov )
            {
               use vars qw/$prov_f/;
               chomp($prov);
               ($prov_f = $prov) =~ s/\+/\\\+/g;
               push(@requires, $prov) if ! grep (/$prov_f/, @requires);
               push(@{$required{$req}}, $prov);
            }
         }
      }
      else
      {
         foreach ( @{$required{$req}} )
         {
            use vars qw/$prov_f/;
            ($prov_f = $_) =~ s/\+/\\\+/g;
            push(@requires, $_) if ! grep (/$prov_f/, @requires);
         }
      }
   }

   return @requires;
}

# input rpm and array to check against
# return array of available matches
sub rpm_matches
{
   my($rpm, @list) = @_;
   use vars qw/$head @avail/;

   $head = (split_name($rpm))[0];

   @avail = grep {
                    my($nhead) = (split_name($_))[0];
                    $_ if $nhead eq $head;
                 } @list;

   if ( $#avail < 0 )
   { return -1; }
   else
   { return @avail; }
}

# input rpm and array of list to check against
# return string of latest version or -1
# return 0 if item is blacklisted
sub latest_version
{
   my($rpm, @list) = @_;
   use vars qw/$head $vers $arch $avail/;

   return 0 unless rpm_matches($rpm, @blacklist) == -1;

   ($head, $vers, $arch) = split_name($rpm);

   my($latest_ver) = -1;
   foreach $avail ( rpm_matches($rpm, @list) )
   {
      use vars qw/$ahead $avers $aarch/;
      ($ahead, $avers, $aarch) = split_name($avail);

      next if $head ne $ahead;
      next if ("$arch" and ($arch ne $aarch));

      my($compare) = vercmp($vers, $avers);
      if ( $compare < 0 )
      {
         use vars qw/$f/;
         $vers = $avers;
         $latest_ver = $avail;
      }
      elsif ( !$compare and $latest_ver eq -1 )
      { $latest_ver = $avail; }
      elsif ( $compare > 0 and $latest_ver eq -1 )
      { $latest_ver = $rpm; }
   }

   return $latest_ver;
}

sub split_name
{
   my($rpm) = @_;

   my($rpm_regex) = '^(.*)\-(.*\-.*?)(?:\.('.$archs.')(\.rpm|\*)?|\*)?$';

   if ( $rpm ne "" && basename($rpm) =~ /${rpm_regex}$/ )
   { return $1, $2, $3; }
   else
   { return -1; }
}

1;
