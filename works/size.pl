#!/usr/local/bin/perl


my $size = 20666904;


sub sizeH {
    my $size = shift;
    return $size if $size < 1024;
    return int($size/1024+0.5)."k" if ($size < 1024*1024 && $size > 1024);
    return int($size/(1024*1024+0.5))."M" if ($size < 1024*1024*1024 && $size > 1024*1024);
    return int($size/(1024*1024*1024)+0.5)."G" if ($size < 1024*1024*1024*1024 && $size > 1024*1024*1024);
}

sub sizeWP {
    my $size = shift;
    $size =~ s/(\d{9})$/.$1/g;
    $size =~ s/(\d{6})$/.$1/g;
    $size =~ s/(\d{3})$/.$1/g;
    return $size;
}


print sizeWP($size)."\n";

#EOF
