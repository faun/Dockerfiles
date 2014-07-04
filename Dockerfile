FROM phusion/passenger-customizable:0.9.11

MAINTAINER Sascha Faun Winter <github@faun.me>
# VERSION 0.1.0

# Set correct environment variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -q

# Use baseimage-docker's init process
CMD ["/sbin/my_init"]

# Build system and git
RUN /build/utilities.sh

# Install rbenv
RUN git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv

# Configure rbenv
RUN echo '# rbenv setup' > /etc/profile.d/rbenv.sh
RUN echo 'export RBENV_ROOT=/usr/local/rbenv' >> /etc/profile.d/rbenv.sh
RUN echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN chmod +x /etc/profile.d/rbenv.sh
RUN . /etc/profile.d/rbenv.sh
RUN echo ". /etc/profile.d/rbenv.sh" >> ~/.bashrc

# Add rbenv to the PATH
RUN echo 'export PATH="/usr/local/rbenv/bin:$PATH"' >> ~/.bashrc

# Install ruby-build
RUN mkdir -p /usr/local/rbenv/plugins
RUN git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build
RUN /usr/local/rbenv/plugins/ruby-build/install.sh

# Add ruby-build to the PATH
RUN echo 'export PATH="/usr/local/rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc

# Install Ruby 2.1 from brightbox PPA
RUN add-apt-repository ppa:brightbox/ruby-ng-experimental
RUN apt-get update
RUN apt-get install -q -y libssl-dev ruby2.1 ruby2.1-dev

# Install base gems
RUN echo "gem: --no-ri --no-rdoc" > /etc/gemrc
RUN gem install rake bundler rdoc --no-rdoc --no-ri
RUN /usr/local/rbenv/bin/rbenv rehash

# Fix shebang lines in rake and bundler so that they're run with the currently
# configured default Ruby instead of the Ruby they're installed with.
RUN sed -i 's|/usr/bin/env ruby.*$|/usr/bin/env ruby|; s|/usr/bin/ruby.*$|/usr/bin/env ruby|' \
  /usr/local/bin/rake /usr/local/bin/bundle /usr/local/bin/bundler

# Common development headers necessary for many Ruby gems,
# e.g. libxml for Nokogiri.
RUN /build/devheaders.sh

# Node.js and Meteor support
RUN /build/nodejs.sh

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
