sub hello {
    my $self = shift;

#    my $name = $self->req->param('name');
#    my $asub = Mojo::IOLoop::Subprocess->new;
#
#    $asub->run(
#        sub {
#            my $subprocess = shift;
#            my $pid = $subprocess->pid;
#            $self->app->log->info("Create subprocess with name=$name"); 
#            sleep 5;
#        },
#        sub {
#            my ($subprocess, $err, @results) = @_;
#            my $pid = $subprocess->pid;
#            $self->app->log->info("End subprocess $pid"); 
#        }
#    );

#    my $username = $self->basicAuth($self->req->headers) || "anonymous";
#    $self->app->log->info("Auth ok") unless $username eq "anonymous";
    $self->render(json => { message => 'hello' } );
}
