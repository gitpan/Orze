package Orze;

=head1 NAME

Orze - Another static website generator

=head1 VERSION

Version 1.0

=head1 DESCRIPTION

This module is only intended to be used by the script orze.

See L<Orze::Manual> for more information.

=cut

use strict;
use warnings;

use Orze::Modules;

our $VERSION = '1.0';

# default value for attributes
my %defaults = (
                driver => "Template",
                template => "index",
                inmenu => 1,
                extension => "html",
                pubmode => "g+rX",
                pubgroup => "www-data",
                outputdir => "",
                );

sub new {
    my ($name, $project, %options) = @_;
    my $self = {};
    bless $self;

    my $site = {
        pages => {},
        variables => {},
    };

    $self->{project} = $project;
    $self->{options} = \%options;
    $self->{site} = $site;

    return $self;
}

###########################################################################
sub propagate {
    my ($self, $page, $path) = @_;
    my $parent = $page->parent;

    $path = '' unless defined($path);

    if (defined($parent)) {
        print "Reading " . $path . $page->att('name') . "\n";
        foreach (keys %{$parent->{'att'}}) {
            if (!defined($page->att($_))) {
                $page->set_att($_ => $parent->att($_));
            }
        }

        my %vars = ();
        foreach ($page->children('var')) {
            $vars{$_->att('name')} = 1;
        }

        foreach ($page->parent->children('var')) {
            if (!exists($vars{$_->att('name')})) {
                my $var = $_->copy;
                $var->paste(first_child => $page);
            }
        }
    }
    else {
        foreach (keys %defaults) {
            if (!defined($page->att($_))) {
                $page->set_att($_ => $defaults{$_});
            }
        }
    }

    $page->set_att(path => $path);
    foreach ($page->children('page')) {
        my $newpath = "";
        if (defined($parent)) {
            $newpath = $path . $page->att('name') . "/";
        }
        $self->propagate($_, $newpath);
    }
}

###########################################################################
sub evaluate {
    my ($self, $page, $site) = @_;

    if ($page->parent) {
        my $path = $page->att('path');
        my $name = $page->att('name');
        print "Evaluating in " . $path . $name . "\n";
    }
    else {
        print "Evaluating in /\n";
    }

    foreach ($page->children('var')) {
        my $varname = $_->att('name');

        if (defined($_->att('src'))) {
            my $module_name = $_->att('src');
            my $module = loadSource($module_name);

            my $source = $module->new($page, $_);
            $site->{variables}->{$varname} = $source->evaluate();
        }
        else {
            $site->{variables}->{$varname} = $_->text;
        }
    }

    foreach ($page->children('page')) {
        my $name = $_->att('name');
        $site->{pages}->{$name} = {
            pages => {},
            variables => {},
        };
        $self->evaluate($_, $site->{pages}->{$name});
    }
}

###########################################################################
sub process {
    my ($self, $page, $site) = @_;

    my @without = @{$self->{options}->{without}};

    if ($page->parent) {
        my $path = $page->att('path');
        my $name = $page->att('name');

        my $module_name = $page->att('driver');
        if (grep {$_ eq $module_name} @without) {
            print "Skipping of " . $path
                . $name . " because of " . $module_name . "\n";
        }
        else {
            my $module = loadDriver($module_name);

            my $driver = $module->new($page, $site->{variables});

            print "Processing of " . $path
                . $name . " with " . $module_name . "\n";

            $driver->process();
        }
    }

    foreach ($page->children('page')) {
        my $name = $_->att('name');
        $self->process($_, $site->{pages}->{$name}, @without);
    }
}

###########################################################################
sub scripts {
    my ($self, $page) = @_;

    if ($page->children('script')) {
        my $loc;
        if ($page->parent) {
            $loc = $page->att('path') . $page->att('name');
        }
        else {
            $loc = "/";
        }
        print "Running scripts in ", $loc, "\n";
    }

    foreach ($page->children('script')) {
        system $_->text;
    }

    foreach ($page->children('page')) {
        $self->scripts($_);
    }
}

###########################################################################
sub post {
    my ($self) = @_;

    my $pub = shift;
    if ($pub) {
        system "chgrp " . $defaults{pubgroup} . " -R www/";
        system "chmod " . $defaults{pubmode} . " -R www/";
    }
}

###########################################################################
sub compile {
    my ($self) = @_;

    my $project = $self->{project};
    my $site = $self->{site};

    $self->propagate($project->root);
    $self->evaluate($project->root, $site);
    $self->process($project->root, $site);
    $self->scripts($project->root);
    $self->post();
}

