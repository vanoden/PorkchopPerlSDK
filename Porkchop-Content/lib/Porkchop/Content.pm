#######################################################
### Porkchop::Content								###
### Interfaces with Porkchop::Content module API.	###
### A. Caravello - 9/16/2014						###
#######################################################
package Porkchop::Content;

# Load Modules
use 5.010001;
use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use HTTP::Cookies::Netscape;
use XML::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Porkchop::Content ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	error
	config
);

our $VERSION = '0.01';

# Object Constructor
sub new
{
	my $package = shift;
	my $self = bless({}, $package);
	my $options = shift;

	$self->{config} = {
		'protocol'		=> 'http',
		'path'			=> '',
		'user-agent'	=> 'Porkchop::Content/'.$VERSION,
	};

	foreach my $option(keys %{$options})
	{
		unless($self->config($option,$options->{$option}))
		{
			return 0;
		}
	}
	return $self;
}

# Configuration
sub config
{
	my ($self,$option,$value) = @_;

	if ($option =~ /^(protocol|login|password|hostname|path$)/)
	{
		$self->{config}->{$option} = $value;
		return 1;
	}
	else
	{
		$self->{error} = "Invalid config option";
		return 0;
	}
}

# Create a web session
sub connect
{
	my ($self) = @_;
	
	# Validate Connection Parameters
	unless ($self->{config}->{protocol})
	{
		$self->{config}->{protocol} = 'http';
	}
	unless ($self->{config}->{protocol} =~ /^http/)
	{
		$self->{error} = "Session protocol must be 'http' or 'https'";
		return $self;
	}
	unless ($self->{config}->{hostname})
	{
		$self->{error} = 'Hostname Required';
		return $self;
	}
	unless ($self->{config}->{hostname} =~ /^\w[\w\-\.]+\w$/)
	{
		$self->{error} = 'Invalid Hostname';
		return $self;
	}

	# Build URL from Parameters
    $self->{url} = $self->{config}->{protocol}."://".$self->{config}->{hostname}."/";
	$self->{url} .= $self->{config}->{path}."/" if ($self->{config}->{path});
	$self->{url} .= "_content/api";

	# Support session cookie
	$self->{cookie_jar} = HTTP::Cookies::Netscape->new(
		file => "cookies.txt",
	);

	# Initiate User Agent
	$self->{ua} = LWP::UserAgent->new()
		or die "Cannot initialize LWP::UserAgent\n";
	$self->{ua}->agent($self->{config}->{'user-agent'});
	$self->{ua}->cookie_jar( $self->{cookie_jar} );

	# Ping Site To Make Sure We're Ready
	my $response = $self->{ua}->post(
		$self->{url},
		Content_Type	=> 'form-data',
		Content			=>
		[   login           => $self->{config}->{login},
            password        => $self->{config}->{password},
			method			=> 'ping',
		]
    );

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Failed to communicate with server during initialization: ".$response->status_line;
		if (my $message = $response->content())
		{
			$self->{error} .= "[ $message ]";
		}
		return $self;
	}

	my $result = eval{
        XMLin($response->content(),KeyAttr => [],"ForceArray" => []);
    };
	if ($@)
	{
		$self->{error} = "Error pinging service: Cannot parse response: $@\n".$response->content();
		return $self;
	}
	unless ($result->{success} == 1)
	{
		$self->{error} = "Error pinging service: $result->{message}";
		return $self;
	}
	# Return Package
	return $self;
}

# Add a Message
sub addMessage
{
	my $self = shift;
	my $parameters;
	$self->{error} = undef;
	if (@_ > 1)
	{
		$parameters->{target} = shift;
		$parameters->{message} = shift;
	}
	else
	{
		$parameters = shift;
	}

	# Return Package
	my $result = $self->sendRequest(
		'addMessage',
		$parameters
	);
	return $result->{message};
}
# Update a Message
sub updateMessage
{
	my $self = shift;
	my $parameters;
	$self->{error} = undef;
	if (@_ > 1)
	{
		$parameters->{target} = shift;
		$parameters->{message} = shift;
	}
	else
	{
		$parameters = shift;
	}

	# Return Package
	my $result = $self->sendRequest(
		'updateMessage',
		$parameters
	);
	return $result->{message};
}
# Get Message
sub getMessage
{
	my ($self,$parameters) = shift;
	$self->{error} = undef;

	# Return Package
	my $result = $self->sendRequest(
		'getMessage',
		$parameters
	);
	return $result->{message};
}
# Find Messages
sub findMessages
{
	my ($self,$parameters) = shift;
	$self->{error} = undef;

	# Return Package
	my $result = $self->sendRequest(
		'findMessages',
		$parameters
	);
	return $result->{message};
}

# Add Metadata
sub addMetadata
{
	my $self = shift;
	my $parameters = shift;
	$self->{error} = undef;

	# Return Package
	my $result = $self->sendRequest(
		'addMetadata',
		$parameters
	);
	return $result->{metadata};
}
# Update Metadata
sub updateMetadata
{
	my $self = shift;
	my $parameters = shift;
	$self->{error} = undef;

	# Return Package
	my $result = $self->sendRequest(
		'updateMetadata',
		$parameters
	);
	return $result->{metadata};
}
# Get Specified Metadata
sub getMetadata
{
	my $self = shift;
	my $parameters = shift;
	$self->{error} = undef;

	# Return Package
	my $result = $self->sendRequest(
		'getMetadata',
		$parameters
	);
	return $result->{metadata};
}
# Find Metadata
sub findMetadata
{
	my $self = shift;
	my $parameters = shift;
	$self->{error} = undef;

	# Return Package
	my $result = $self->sendRequest(
		'findMetadata',
		$parameters
	);
	return $result->{metadata};
}
# Send Request to Service
sub sendRequest
{
	my ($self,$method,$parameters) = @_;
	
	$parameters->{method} = $method;

	# Add Message Via API
	my $response = $self->{ua}->post(
		$self->{url},
		Content_Type	=> 'form-data',
		Content			=> $parameters
    );

	my $result = eval{
		XMLin($response->content(),KeyAttr => [],"ForceArray" => []);
    };
	if ($@)
	{
		$self->{error} = "Error communicating with service: Cannot parse response: $@\n".$response->content();
		return undef;
	}
	unless ($result->{success} == 1)
	{
		$self->{error} = "Error from service: $result->{message}";
		return undef;
	}
	return $result;
}

1;
__END__

=head1 NAME

Porkchop::Content - Perl extension for Interfacing with the
Porkchop Content module API.

=head1 SYNOPSIS

  use Porkchop::Content;
  $content = Porkchop::Content->new();
  
  $content->findMessage({'target' => 'myMessage'});
  die "Error finding message: ".$content->{error}."\n" if ($content->{error});

  $content->addMessage({
    
  })

=head1 DESCRIPTION

This module exposes the Porkchop CMS Content Module's API to
your perl script.  It allows for adding and editing content
in your Porkchop web site via an external application.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>tony@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
