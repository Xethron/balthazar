Balthazar Ruby IRC Bot
=============================

*Balthazar is an IRC bot based on Coolfire's Nanobot*

Balthazar was a personal holiday project to learn Ruby. It was abandoned after I started working, and was uploaded for educational purposes only on a friends request.

The idea behind Balthazar was to create a MySQL based stats bot with dictionary support, and profile users to help OP's with useful information on every user connected to their channel.

While the bot is far from complete, its provided me with a lot of joy and entertainment throughout the holidays and I hope some of you will be able to learn from my mistakes and maybe even take Balthazar to new heights.

While I am not currently actively involved in the project any more, it would bring me great joy to see others push new code to the project. So if you have made some improvements, you are most welcome to send in a pull request and I'll gladly accept it!

Changes in Balthazar
---------------------------
Here is a list of changes that I made from Nanobot:

- Added MySQL support
- Added Aspell support
- Improved bot admin check to include user and hostname
- Major changes to ircparser
    - Added Part reason
    - Added nick change
    - Added Server Messages
    - Added Mode Changes
    - Added Topic Changes
- Changes to ircparser_subroutines
    - Added support for above changed functions
    - Support to decode raw messages
        - Whois
        - Message of the day
- New plugins
    - arc.rb
    - choose.rb
    - coffee.rb
    - decarc.rb
    - dev.rb
    - link.rb
    - logs.rb
    - logsv2.rb
    - stat.rb
    - top.rb
    - user.rb
    - whois.rb
    - wolfram.rb

License
--------

Balthazar (Changes from Nanobot) is distributed under the terms of the GNU General Public License, version 3 or later.
<br>Most of the source is based on Nanobot 4, for which the licence is included as LICENSE.
