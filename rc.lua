-- * Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local all_menu_dirs = { '/usr/share/applications/', '/usr/local/share/applications/', '~/.local/share/applications/', '/usr/share/applications/kde4/'}

menubar.menu_gen.all_menu_dirs = all_menu_dirs

require("wicked")
require("freedesktop.utils")
require("obvious")
-- * errors checking
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
   local in_error = false
   awesome.connect_signal("debug::error", function (err)
                                         -- Make sure we don't go into an endless error loop
                                         if in_error then return end
                                         in_error = true

                                         naughty.notify({ preset = naughty.config.presets.critical,
                                                          title = "Oops, an error happened!",
                                                          text = err })
                                         in_error = false
                                      end)
end

-- * Variable definitions
--   Hostname for different configuration for different host
function hostname()
   local f = io.popen ("/bin/hostname")
   local n = f:read("*a") or "none"
   f:close()
   n=string.gsub(n, "\n$", "")
   return(n)
end

hostname = hostname()

if hostname == "toubib" or hostname == "gobelin" then
   session = "systemd"
else
   session = "gnome"
end

if hostname == "gobelin" then
   asbattery = true
else
   asbattery = false
end

theme_path = "/usr/share/awesome/themes/default/theme.lua"
-- Uncommment this for a lighter theme
-- theme_path = "/usr/share/awesome/themes/sky/theme.lua"
-- *** My actual theme
theme_path = "/home/moi/.config/awesome/theme.lua"
-- *** Actually load theme
beautiful.init(theme_path)
-- ** This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"

if session == "systemd" then
   emacs = "systemctl --user start emacs.service"
   xbmc = "systemctl --user start xbmc.service"
   steam = "systemctl --user start steam.service"
   webbrowser = "systemctl --user start iceweasel.service"
else
   emacs = "myemacs-n2"
   xbmc = "xbmc"
   steam = "steam"
   webbrowser = "iceweasel"
end

if session == "gnome" then
   filemanager = "nautilus"
else
   filemanager = "thunar"
end

webbrowser_class = "Iceweasel"
if hostname == "toubib" then
   terminal_class = "Xfce4-terminal"
else
   terminal_class = "gnome-terminal"
end

editor = emacs
editor_cmd = emacs

-- ** Default modkey.
--   Usually, Mod4 is the key with a logo between Control and Alt.
--   If you do not like this or do not have such a key,
--   I suggest you to remap Mod4 to another key using xmodmap or other tools.
--   However, you can use another modifier like Mod1, but it may interact with others.
--
modkey = "Mod4"
spawnkey = { modkey, "Control" }

-- ** Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
   {
   awful.layout.suit.tile,
   --    awful.layout.suit.tile.left,
   awful.layout.suit.tile.bottom,
   --    awful.layout.suit.tile.top,
   awful.layout.suit.fair,
   --    awful.layout.suit.fair.horizontal,
   awful.layout.suit.max,
   awful.layout.suit.max.fullscreen,
   awful.layout.suit.magnifier,
   awful.layout.suit.floating
}

-- ** Screens
if screen.count() ~= 1 then
   left_screen = 1
   right_screen = screen.count()
   main_screen = left_screen
   secondary_screen = right_screen
else
   left_screen = 1
   right_screen = 1
   main_screen = left_screen
   secondary_screen = right_screen
end

-- * Some useful function
function give_info (c)
   text = ""
   if c.class then
      text = text .. "Class: " .. c.class .. " "
   end
   if c.instance then
      text = text .. "Instance: ".. c.instance .. " "
   end
   if c.role then
      text = text .. "Role: ".. c.role
   end
   naughty.notify({text = text, title = "window info", timeout = 5, screen = mouse.screen, ontop = true})
   io.stderr:write (text)
   io.stderr:write "\n"
end

function Set (list)
   local set = {}
   for _, l in ipairs(list) do set[l] = true end
   return set
end

-- Returns true if all pairs in table1 are present in table2
function match (table1, table2)
   for k, v in pairs(table1) do
      if not(table2[k]) or (table2[k] ~= v and not table2[k]:find(v)) then
         return false
      end
   end
   return true
end

-- ** Return clients matching a property
function client_matching(properties)
   local clients = client.get()
   local focused = awful.client.next(0)
   local findex = 0
   local matched_clients = {}
   local n = 0
   for i, c in pairs(clients) do
      --make an array of matched clients
      if match(properties, c) then
         n = n + 1
         matched_clients[n] = c
         if c == focused then
            findex = n
         end
      end
   end
   matched_clients.n = n
   matched_clients.findex = findex
   return matched_clients
end
-- ** Run or raise
--- Spawns cmd if no client can be found matching properties
-- If such a client can be found, pop to first tag where it is visible, and give it focus
-- @param cmd the command to execute
-- @param properties a table of properties to match against clients.  Possible entries: any properties of the client object
function run_or_raise(cmd, properties)
   local matched_clients = client_matching(properties)
   local n = matched_clients.n
   local findex = matched_clients.findex

   if n > 0 then
      local c = matched_clients[1]
      -- if the focused window matched switch focus to next in list
      if 0 < findex and findex < n then
         c = matched_clients[findex+1]
      end
      local ctags = c:tags()
      if table.getn(ctags) == 0 then
         -- ctags is empty, show client on current tag
         local curtag = awful.tag.selected()
         awful.client.movetotag(curtag, c)
      else
         -- Otherwise, pop to first tag client is visible on
         awful.tag.viewonly(ctags[1])
      end
      -- And then focus the client
      client.focus = c
      c:raise()
      return
   end
   awful.util.spawn(cmd)
end

-- ** raise or nothing
-- find a client, raise it if it exist, do nothing if it don't

function raise_or_nothing(properties)
   local matched_clients = client_matching(properties)
   local n = matched_clients.n
   if n > 0 then
      c = matched_clients[1]
      local ctags = c:tags()
      if table.getn(ctags) == 0 then
         -- ctags is empty, show client on current tag
         local curtag = awful.tag.selected()
         awful.client.movetotag(curtag, c)
      else
         -- Otherwise, pop to first tag client is visible on
         awful.tag.viewonly(ctags[1])
      end
      -- And then focus the client
      client.focus = c
      c:raise()
      return
   end
end

-- ** close a client if it exist.
-- find a client, raise it if it exist, do nothing if it don't

function close_from_properties(properties)
   local matched_clients = client_matching(properties)
   local n = matched_clients.n
   if n > 0 then
      c = matched_clients[1]
      c:kill()
      return
   end
end

-- * Tags
-- ** different default for different computer
if hostname == "madame" then
   term_conf = { layout = awful.layout.suit.tile, mfact = 0.5 }
   full_conf = { layout = awful.layout.suit.max, mfact = 0.75 }
   default_main_conf = { layout = awful.layout.suit.tile, mfact = 0.5 }
   default_second_conf = { layout = awful.layout.suit.tile.bottom, mfact = 0.5 }
   float_conf = { layout = awful.layout.suit.floating, mfact = 0.5 }
else
   term_conf = { layout = awful.layout.suit.max, mfact = 0.75 }
   full_conf = { layout = awful.layout.suit.max, mfact = 0.75 }
   default_main_conf = { layout = awful.layout.suit.max, mfact = 0.75 }
   default_second_conf = { layout = awful.layout.suit.max, mfact = 0.75 }
   float_conf = { layout = awful.layout.suit.floating, mfact = 0.5 }
end
-- ** the tags definition
tags_config = {
   { name = "te", tag_conf = { term_conf, default_second_conf }, },
   { name = "em", tag_conf = { full_conf, full_conf }, },
   { name = "net", tag_conf = { full_conf, full_conf }, },
   { name = "pl", tag_conf = { default_main_conf, default_second_conf }, },
   { name = "fm", tag_conf = { default_main_conf, default_second_conf }, },
   { name = "IM", tag_conf = { float_conf, float_conf }, only_on = secondary_screen },
   { name = "sup1", tag_conf = { float_conf, float_conf }, },
   { name = "sup2", tag_conf = { float_conf, float_conf }, only_on = main_screen },
   { name = "cal", tag_conf = { default_main_conf, default_second_conf }, only_on = secondary_screen },
}
-- ** Define a tag table which hold all screen tags.
tags = {}
tag_by_name = { }
print(tags)
for s = 1, screen.count() do
   -- Each screen has its own tag table.
   tags[s] = { }
   for i, t in ipairs(tags_config) do
      if not t.only_on or t.only_on == s then
         t.tag_conf[s].screen = s
         tag=awful.tag.add(t.name,t.tag_conf[s])
         table.insert(tags[s],tag)
         if tag_by_name[t.name] then
            table.insert(tag_by_name[t.name],tag)
         else
            tag_by_name[t.name]= { tag }
         end
      end
   end
   awful.tag.viewtoggle(tags[s][1])
end

-- * Menu
-- ** Load Debian menu entries
require("debian.menu")
require('freedesktop.menu')

freedesktop.menu.all_menu_dirs = all_menu_dirs

-- ** Create a laucher widget and a main menu
hibernate = function ()
               if hostname == "gobelin" then
                  awful.util.spawn("dbus-send --print-reply --session --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock")
               end
               awful.util.spawn("dbus-send --print-reply --system --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower.Hibernate")
            end

suspend = function ()
             if hostname == "gobelin" then
                awful.util.spawn("dbus-send --print-reply --session --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock")
             end
             awful.util.spawn("dbus-send --print-reply --system --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower.Suspend")
          end

gnome_do_logout = function ()
                     awful.util.spawn("dbus-send --session -dest=org.gnome.SessionManager /org/gnome/SessionManager org.gnome.SessionManager.Logout uint32:1")
                  end

gnome_power_off = function ()
                     awful.util.spawn("gnome-session-quit --power-off")
                  end

gnome_quit = function ()
                awful.util.spawn("gnome-session-quit --no-prompt --logout")
             end

systemd_quit = function ()
                  awful.util.spawn("systemctl --user start session-quit.service")
               end

systemd_power_off = function ()
                      awful.util.spawn("systemctl --user start poweroff.service")
                   end

if session == "systemd" then
   quit_menu = { { "yes", systemd_quit },
                         { "no", function () end },
                         { "hibernate", hibernate },
                         { "halt", systemd_power_off },
                         { "restart", awesome.restart } }
else
   quit_menu = { { "yes", gnome_quit },
                 { "no", function () end },
                 { "hibernate", hibernate },
                 { "suspend", suspend },
                 { "halt", gnome_power_off },
                 { "restart", awesome.restart } }
end


function xrandr_screen()
   local f = io.popen ("/usr/bin/xrandr -q | grep connected | grep -v disconnected | sed 's/\\([A-Z0-9]*\\) .*/\\1/'")
   local n = f:lines()
   return(n)
end

xrandr_num_display = 0
for display in xrandr_screen() do
   xrandr_num_display = xrandr_num_display + 1
end

if hostname == "madame" then
   xrandr_clone_display =
      function ()
         awful.util.spawn("xrandr --output DFP9 --auto --same-as DFP10 --mode 1680x1050 --rotate normal")
         awful.util.spawn("xrandr --output DFP10 --auto --mode 1680x1050")
         awful.util.spawn("xrandr --output HDMI-0 --auto --same-as DVI-0 --mode 1680x1050 --rotate normal")
         awful.util.spawn("xrandr --output DVI-0 --auto --mode 1680x1050")
      end

   xrandr_std_display =
      function ()
         awful.util.spawn("xrandr --output DFP10 --auto --mode 1680x1050")
         awful.util.spawn("xrandr --output DFP9 --rotate left --right-of DFP10 --mode 1680x1050")
         awful.util.spawn("xrandr --output DVI-0 --auto --mode 1680x1050")
         awful.util.spawn("xrandr --output HDMI-0 --rotate left --right-of DVI-0 --mode 1680x1050")
      end
elseif hostname == "gobelin" then
   xrandr_clone_display =
      function ()
         for display in xrandr_screen() do
            if display == "HDMI1" then
               awful.util.spawn("xrandr --output HDMI1 --mode 1360x768 --same-as LVDS1")
               awful.util.spawn("xrandr --output LVDS1 --mode 1360x768 ")
            elseif display == "VGA1" then
               awful.util.spawn("xrandr --output VGA1 --auto --same-as LVDS1 --preferred")
               awful.util.spawn("xrandr --output LVDS1 --auto --preferred")
            end
         end
      end

   xrandr_std_display =
      function ()
         awful.util.spawn("xrandr --output LVDS1 --auto --preferred")
         awful.util.spawn("xrandr --output VGA1 --right-of LVDS1 --auto --preferred")
         awful.util.spawn("xrandr --output HDMI1 --mode 1360x768 --right-of LVDS1")
      end
end

myawesomemenu =
   {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/myconf.lua" },
   { "quit...", quit_menu },
}

if hostname == "gobelin" or hostname == "madame" then
   displaymenutable = { { "clone",    xrandr_clone_display },
                        { "standart", xrandr_std_display   }}
   if hostname == "gobelin" and xrandr_num_display == 2 then
      table.insert(displaymenutable,{ "do not lock", "/home/moi/bin/do-not-lock-screen" })
      table.insert(displaymenutable,{ "do lock", "/home/moi/bin/do-lock-screen" })
   end

   displaymenu =  { "display", displaymenutable }

   table.insert(myawesomemenu,displaymenu)
end

if hostname == "madame" then
   table.insert(myawesomemenu,{ "hibernate to win", function () awful.util.spawn("gksudo /home/moi/bin/hibernate-to-win") end })
end


freedesktop_menu = freedesktop.menu.new()

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal },
                                    { "open emacs", "emacs" },
                                    { "open file manager", filemanager },
                                    { "open webbrowser", webbrowser },
                                    { "windows" , function () awful.menu.clients({},{ width=250 }) end},
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "App", freedesktop_menu },
                                 }
                       })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- ** key menu
xrandr_menu = { }

do
   local fd = io.popen("xrandr")
   local sub_menu = {}
   local mode = ""
   local display = ""
   for line in fd:lines() do
      if not string.find(line, "^Screen ") then
         if string.find(line, "^%S+%sconnected") then
            display = string.match(line, "^%S+")
            sub_menu = {}
            table.insert(xrandr_menu, { display, sub_menu })
         elseif string.find(line, "^%s+%d+x%d+") then
            mode = string.match(line, "%d+x%d+")
            table.insert(sub_menu, { mode, "xrandr --output " .. display .. " --mode " .. mode })
         end
      end

   end
   fd:close()
   -- TODO collapse submenu when only one display is connected
end

mykeymenu = awful.menu({ items = { { "Xbmc", function () run_or_raise(xbmc, { class = "xbmc.bin" }) end },
                                   { "Emacs", function () run_or_raise(emacs, { class = "Emacs" }) end },
                                   { "Web", function () run_or_raise(webbrowser, { class = webbrowser_class }) end },
                                   { "Steam", function () run_or_raise(steam, { class = "Steam" }) end },
                                   { "Term", function () run_or_raise(terminal, { class = terminal_class }) end },
                                   { "performous", "performous" },
                                   { "quit...", quit_menu },
                                   { "Display", xrandr_menu },
                                   { "windows" , function () awful.menu.clients({width=750, }, { keygrabber = true, font_size = 30 }) end},

                                   { "Debian", debian.menu.Debian_menu.Debian },
                                   { "App", freedesktop_menu },
                                }
                      }
                    )

-- * Wibox
-- ** Create a textclock widget
mytextclock = awful.widget.textclock() --({ align = "right" }," %a %d %b, %H:%M ")
-- ** Add an orglendar to the textclock
-- require("orglendar")
-- orglendar.files = {
--    "~/org/prgm.org",
--    "~/org/notes.org",
--    "~/org/mononoke.org",
--    "~/org/personel.org",
--    "~/org/aniversaire.org",
--    "~/org/cours.org",
--    "~/travail/cours/premiere/2011-2012 S/premiere-S1-G1.org",
-- }
-- orglendar.register(mytextclock)

-- ** Create a widget for when reboot is required
-- *** The function to check the situation
function reboot_required()
   tmp = io.open('/var/run/reboot-required')
   if tmp then
      tmp:close()
      return '<span color="red">Reboot required</span>'
   else
      return ""
   end
end
-- *** The widget
-- myneedreboot = wibox.widget.textbox()
-- lib.hooks.timer.register(5, 30, function() myneedreboot:set_text(reboot_required()) end)
-- ** Create a systray
mysystray = wibox.widget.systray()
-- ** Create a cpuwidget
cpuwidget=obvious.cpu()
cpuwidget:set_width(20)
cpuwidget:set_background_color("#494B4F")
cpuwidget:set_color("#FF5656")
-- cpuwidget:set_gradient_colors({ "#FF5656", "#88A175", "#AECF96" })

memwidget = obvious.mem()
memwidget:set_width(20)
memwidget:set_background_color("#494B4F")
memwidget:set_color("#0000ff")
-- memwidget:set_gradient_colors({ "#0000ff", "#00bfff", "#00ffff" })
-- ** Create a keyboard widget
-- obvious.keymap_switch.set_layouts({ "fr(bepo)", "fr(oss)" })

-- keywidget = obvious.keymap_switch()
-- ** Create a keyboard widget
-- *** The table of keymap
keyreverse = { }
keyreverse["fr(bepo)"] = "bépo"
keyreverse["fr(oss)"] = "azer"
keyreverse["us"] = "qwer"

keyboard_layout = { }
keyboard_layout["bépo"]="fr(bepo)"
keyboard_layout["azer"]="fr(oss)"
keyboard_layout["qwer"]="us"

-- *** The function to check the situation
function get_current_keymap()
   local fd = io.popen("setxkbmap -print")
   if not fd then return end

   for line in fd:lines() do
      if line:match("xkb_symbols") then
         local keymap = line:match("\+[^+]*\+")

         fd:close()
         if not keymap then
            return "unknown layout"
         else if keyreverse[keymap:sub(2, -2)] then
               return keyreverse[keymap:sub(2, -2)]
            else
               return keymap:sub(2, -2)
            end
         end
      end
   end

   fd:close()
   return "unknown layout"
end
-- *** Changing configuration
function switch_keymap(layout_string)
   if keyboard_layout[layout_string] then
      awful.util.spawn("setxkbmap \"" .. keyboard_layout[layout_string] .. "\"")
      update_keywidget(layout_string)
   else
      awful.util.spawn("setxkbmap \"" .. layout_string .. "\"")
   end
end
-- *** The menu
keymenu =  awful.menu.new({ items =
                            { { "bépo", function () switch_keymap "bépo" end, nil },
                              { "azerty", function () switch_keymap "azer" end, nil },
                              { "qwerty", function () switch_keymap "us" end, nil },
                           }
                      }
                    )

-- *** The widget
keywidget = wibox.widget.textbox()
keywidget:set_text("...")
update_keywidget = function() keywidget:set_text(get_current_keymap()) end
update_keywidget()
keywidget:buttons(awful.util.table.join(
                     awful.button({ }, 1, function ()
                                             keymenu:toggle()
                                          end),
                     awful.button({ }, 3, function ()
                                             keymenu:toggle()
                                          end),
                     awful.button({ }, 4, awful.tag.viewnext),
                     awful.button({ }, 5, awful.tag.viewprev)
               ))


-- awful.hooks.timer.register(120, update_keywidget)

--  obvious.keymap_switch.set_layouts({ "fr(bepo)", "fr(oss)" })
-- ** Create a widget for each screen.
-- *** First define array for each type of widget
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
-- *** The array for the tag list and its buttons
mytaglist = {}

mytaglist.buttons = awful.util.table.join(
   awful.button({ }, 1, awful.tag.viewonly),
   awful.button({ modkey }, 1, awful.client.movetotag),
   awful.button({ }, 3, awful.tag.viewtoggle),
   awful.button({ modkey }, 3, awful.client.toggletag),
   awful.button({ }, 4, awful.tag.viewnext),
   awful.button({ }, 5, awful.tag.viewprev)
)
-- *** The array for the task list and its buttons
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
   awful.button({ }, 3, function (c)
                           if c.maximized_horizontal then
                              max_icon = beautiful.titlebar_maximized_button_focus_active
                           else
                              max_icon = beautiful.titlebar_maximized_button_focus_inactive
                           end
                           if awful.client.floating.get(c) then
                              float_icon = beautiful.titlebar_floating_button_focus_active
                           else
                              float_icon = beautiful.titlebar_floating_button_focus_inactive
                           end
                           if c.sticky then
                              sticky_icon = beautiful.titlebar_sticky_button_focus_active
                           else
                              sticky_icon = beautiful.titlebar_sticky_button_focus_inactive
                           end
                           if instance then
                              instance:hide()
                              instance = nil
                           else
                              instance = awful.menu.new({ items =
                                                          { { "close", function () c:kill() end, beautiful.titlebar_close_button_focus },
                                                            { "maximize", function ()
                                                                             c.maximized_horizontal = not c.maximized_horizontal
                                                                             c.maximized_vertical = not c.maximized_vertical
                                                                          end, max_icon },
                                                            { "float", function ()
                                                                          awful.client.floating.toggle(c)
                                                                       end, float_icon },
                                                            { "sticky", function ()
                                                                           c.sticky=not c.sticky
                                                                        end, sticky_icon },
                                                            { "info", function () give_info(c) end, nil },
                                                            { "raise", function () c:raise() end, nil },
                                                            { "focus", function () awful.client.focus.byidx(0, c) end, nil }}})
                              instance:show()
                           end
                        end),
   awful.button({ }, 4, function ()
                           awful.client.focus.byidx(1)
                           if client.focus then client.focus:raise() end
                        end),
   awful.button({ }, 5, function ()
                           awful.client.focus.byidx(-1)
                           if client.focus then client.focus:raise() end
                        end))

-- *** No realy create those widget
for s = 1, screen.count() do
-- **** Create a promptbox for each screen
   mypromptbox[s] = awful.widget.prompt() --({ layout = awful.widget.layout.horizontal.leftright })
-- **** Create an imagebox widget which will contains an icon indicating which layout we're using.
--      We need one layoutbox per screen.
   mylayoutbox[s] = awful.widget.layoutbox(s)
   mylayoutbox[s]:buttons(awful.util.table.join(
                             awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                             awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                             awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                             awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
-- **** Create a taglist widget
   mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
-- **** Create a tasklist widget
   mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)
-- **** Create the wibox
   mywibox[s] = awful.wibox({ position = "top", screen = s })
-- **** Add widgets to the wibox - order matters
   local left_layout = wibox.layout.fixed.horizontal()
   if s == left_screen then
      left_layout:add(mylauncher)
   end
   left_layout:add(mytaglist[s])
   left_layout:add(mypromptbox[s])
   -- leftbox.layout = awful.widget.layout.horizontal.leftright

   local right_layout = wibox.layout.fixed.horizontal()
   right_layout:add(keywidget)
   if s == secondary_screen then right_layout:add(mysystray) end
   right_layout:add(memwidget[1])
   right_layout:add(cpuwidget[1])
   if asbattery then
      right_layout:add(obvious.battery())
   end
   right_layout:add(mytextclock)
   right_layout:add(mylayoutbox[s])
   --right_layout:add(myneedreboot)

   -- Now bring it all together (with the tasklist in the middle)
   local layout = wibox.layout.align.horizontal()
   layout:set_left(left_layout)
   layout:set_middle(mytasklist[s])
   layout:set_right(right_layout)

   mywibox[s]:set_widget(layout)
end

-- * Mouse bindings
root.buttons(awful.util.table.join(
                awful.button({ }, 3, function () mymainmenu:toggle() end),
                awful.button({ }, 4, awful.tag.viewnext),
                awful.button({ }, 5, awful.tag.viewprev)
          ))

-- * Key bindings
-- ** first useful functions to create keybinding to spawn command
-- *** simple spawn
function key_spawn (mod, key, cmd)
   return awful.key(mod, key, function () awful.util.spawn(cmd) end)
end
-- *** another function for run_or_raise
function key_run_or_raise (mod, key, cmd, prop)
   return awful.key(mod, key, function () run_or_raise(cmd, prop) end)
end
-- *** Change screen relatively to current screen
function screen_focus_relative_right()
   if client.focus and client.focus.screen then
      if client.focus.screen < screen.count() then
         awful.screen.focus(client.focus.screen + 1)
      else
         awful.screen.focus(1)
      end
   else
      awful.screen.focus_relative( 1)
   end
end

function screen_focus_relative_left()
   if client.focus and client.focus.screen then
      if client.focus.screen > 1 then
         awful.screen.focus(client.focus.screen - 1)
      else
         awful.screen.focus(screen.count())
      end
   else
      awful.screen.focus_relative(-1)
   end
end

-- ** the global keys
globalkeys = awful.util.table.join(
-- *** The multimedia keys and standard program
--     Do not forget to tell gnome to not interfere, and to let us play with them
   key_spawn({}, "XF86PowerOff",         "systemctl hibernate"),
   key_spawn({}, "XF86AudioPlay",        "nyxmms2 toggle"),
   key_spawn({}, "XF86AudioStop",        "nyxmms2 stop"),

   key_spawn({}, "XF86AudioPrev",        "nyxmms2 prev"),
   key_spawn({}, "XF86AudioNext",        "nyxmms2 next"),

   key_spawn({ "Ctrl" }, "XF86AudioPlay",        "nyxmms2 stop"),
   key_spawn({ "Ctrl" }, "XF86AudioNext",        "xmms-rater 1; nyxmms2 next"),

   key_spawn({}, "XF86AudioRaiseVolume", "pactl set-sink-volume 0 +2%"),
   key_spawn({}, "XF86AudioLowerVolume", "pactl set-sink-volume 0 -2%"),
   key_spawn({}, "XF86AudioMute",        "amixer set Master toggle"),
   key_spawn({}, "XF86Sleep",            "sudo pm-hibernate"),

   key_spawn(spawnkey, "Return",         terminal),
   key_spawn(spawnkey, "t",              filemanager),

   key_run_or_raise({}, "XF86AudioMedia", xbmc,                       { class = "xbmc.bin" }),
   key_run_or_raise({}, "XF86Tools",      xbmc, { class = "xbmc.bin" }),
   key_run_or_raise(spawnkey, "v",        "gnome-control-center sound", { class = "gnome-control-center" }),
   key_run_or_raise({}, "XF86HomePage",   webbrowser,                   { class = webbrowser_class }),
   key_run_or_raise(spawnkey, "f",        webbrowser,                   { class = webbrowser_class }),
   key_run_or_raise({}, "XF86Mail",       emacs,                        { class = "Emacs" }),
   key_run_or_raise(spawnkey, "e",        emacs,                        { class = "Emacs" }),
   key_run_or_raise({}, "XF86Launch7",    steam,                        { class = "Steam" }),
-- *** Moving trough the tags
   awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
   awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
   awful.key({ modkey,           }, "Escape", awful.tag.history.restore),
-- **** The same but for the other screen
   awful.key({ modkey, "Control" }, "Left", function ()
                                               screen_focus_relative_right()
                                               awful.tag.viewprev()
                                               screen_focus_relative_left()
                                            end),
   awful.key({ modkey, "Control" }, "Right", function ()
                                                screen_focus_relative_right()
                                                awful.tag.viewnext()
                                                screen_focus_relative_left()
                                             end),
   awful.key({ modkey, "Control" }, "Escape", function ()
                                                 screen_focus_relative_right()
                                                 awful.tag.history.restore()
                                                 screen_focus_relative_left()
                                              end),
-- *** Changing focus
   awful.key({ modkey,           }, "j",
             function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ modkey,           }, "n",
             function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ modkey,           }, "k",
             function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ modkey,           }, "p",
             function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ modkey,           }, "s",
             function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ modkey,           }, "t",
             function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
             end),

   awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
   awful.key({ modkey,           }, "Tab",
             function ()
                awful.client.focus.history.previous()
                if client.focus then
                   client.focus:raise()
                end
             end),
   awful.key({ modkey,           }, ",", function ()
                                            awful.menu.clients({}, { width = 250, keygrabber = true })
                                         end),
   awful.key({ modkey,           }, "$", function () mykeymenu:toggle({ keygrabber = true }) end),
   awful.key({         }, "XF86LaunchB", function () mykeymenu:toggle({ keygrabber = true }) end),
-- *** Show the main menu
   awful.key({ modkey,           }, "w", function () mymainmenu:toggle()        end),
-- *** Layout manipulation
   awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
   awful.key({ modkey, "Shift"   }, "n", function () awful.client.swap.byidx(  1)    end),
   awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
   awful.key({ modkey, "Shift"   }, "p", function () awful.client.swap.byidx( -1)    end),
   awful.key({ modkey, "Control" }, "j",   screen_focus_relative_right),
   awful.key({ modkey, "Control" }, "n",   screen_focus_relative_right),
   awful.key({ modkey, "Shift"   }, "Tab", screen_focus_relative_right),
   awful.key({ modkey, "Control" }, "k",   screen_focus_relative_left),
   awful.key({ modkey, "Control" }, "p",   screen_focus_relative_left),

   awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
   awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
   awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
   awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
   awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
   awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
   awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
   awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
-- *** Meta
   awful.key({ modkey, "Control" }, "r", awesome.restart),

   awful.key({ modkey, "Shift"   }, "q", function ()
                                            awful.menu({ items = quit_menu }):show({ keygrabber = true })
                                         end ),

-- *** Prompt
   awful.key({ modkey },            "r",     function() menubar.show() end),

   awful.key({ modkey }, "x",
             function ()
                awful.prompt.run({ prompt = "Run Lua code: " },
                                 mypromptbox[mouse.screen].widget,
                                 awful.util.eval, nil,
                                 awful.util.getdir("cache") .. "/history_eval")
             end)
-- *** Closing the keys
)
-- ** the client keys
clientkeys = awful.util.table.join(
   awful.key({ modkey, "Ctrl"    }, "i",      give_info),
   awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
   awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
   awful.key({ modkey, "Control" }, "c",      function (c) c:kill()                         end),
   awful.key({ modkey, "Control" }, "w",      function (c) c:kill()                         end),
   awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
   awful.key({ modkey,           }, "Return", function (c) c:swap(awful.client.getmaster()) end),
   awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
   awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
   awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
   awful.key({ modkey,           }, "m",
             function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c.maximized_vertical   = not c.maximized_vertical
             end)
)

-- ** tags specific keys
-- *** Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- *** Bind all key numbers to tags.
--     Be careful: we use keycodes to make it works on any keyboard layout.
--     This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
   globalkeys = awful.util.table.join(globalkeys,
                                      awful.key({ modkey }, "#" .. i + 9,
                                                function ()
                                                   local screen = mouse.screen
                                                   if tags[screen][i] then
                                                      awful.tag.viewonly(tags[screen][i])
                                                   end
                                                end),
                                      awful.key({ modkey, "Control" }, "#" .. i + 9,
                                                function ()
                                                   screen_focus_relative_right()
                                                   local screen = mouse.screen
                                                   if tags[screen][i] then
                                                      awful.tag.viewonly(tags[screen][i])
                                                   end
                                                   screen_focus_relative_left()
                                                end),
                                      awful.key({ modkey, "Shift" }, "#" .. i + 9,
                                                function ()
                                                   if client.focus and tags[client.focus.screen][i] then
                                                      awful.client.movetotag(tags[client.focus.screen][i])
                                                   end
                                                end),
                                      awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                                                function ()
                                                   if client.focus and tags[client.focus.screen][i] then
                                                      awful.client.toggletag(tags[client.focus.screen][i])
                                                   end
                                                end))
end

-- ** mousse button for clients
clientbuttons = awful.util.table.join(
   awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
   awful.button({ modkey }, 1, awful.mouse.client.move),
   awful.button({ modkey }, 3, awful.mouse.client.resize))

-- ** Set keys
root.keys(globalkeys)

-- * Rules
awful.rules.rules = {
   -- All clients will match this rule.
   { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
   { rule = { class = "Calibre-gui", instance = "calibre-gui" },
     properties = { tag = tag_by_name["cal"][1] } },
   { rule = { class = "Iceweasel", instance = "Navigator" },
     properties = { tag = tag_by_name["net"][main_screen] } },
   { rule = { class = "Chromium" },
     properties = { tag = tag_by_name["net"][main_screen] } },
   { rule = { class = "Steam" },
     properties = { tag = tag_by_name["sup2"][main_screen] } },
   { rule = { class = "MPlayer" },
     properties = { floating = true } },
   { rule = { class = "pinentry" },
     properties = { floating = true } },
   { rule = { class = "gimp" },
     properties = { floating = true } },
   { rule = { class = "Emacs" },
     properties = { tag = tag_by_name["em"][main_screen],
                    size_hints_honor = false } },
   { rule = { class = "Miro.real"},
     properties = { tag = tag_by_name["pl"][main_screen] } },
   { rule = { instance = "gajim.py" },
     properties = { tag = tag_by_name["IM"][secondary_screen] } },
   { rule = { class = "Transmission" },
     properties = { tag = tag_by_name["sup2"][main_screen] } },
   { rule = { instance = "xmms-gtk-rater" },
     properties = { tag = tag_by_name["pl"][secondary_screen] } },
   { rule = { instance = "cairo-dock" },
     properties = { ontop = true } },
   { rule = { instance = "cairo-dock" },
     properties = { ontop = true, focusable = false } },
   { rule = { instance = "abraca" },
     properties = { tag = tag_by_name["pl"][secondary_screen] } },
   { rule = { class = "Pidgin" },
     properties = { tag = tag_by_name["IM"][secondary_screen] } },
   { rule = { instance = "x-nautilus-desktop" },
     properties = { focusable = false } },

}

-- ** Black magick for chromium or iceweasel on both screen
function select_browser(tag)
   local clients = client.get()
   local properties = { class = webbrowser_class }

   if(tag_by_name["net"][main_screen].selected) then
      ntag = tag_by_name["net"][main_screen]
   elseif (tag_by_name["net"][secondary_screen].selected) then
      ntag = tag_by_name["net"][secondary_screen]
   else
      return nil
   end
   for i, c in pairs(clients) do
      if match(properties, c) then
         c.screen=awful.tag.getscreen(ntag)
         c:tags({ ntag })
      end
   end
end

if not(main_screen == secondary_screen) then
   for s = main_screen, secondary_screen do
      tag_by_name["net"][s]:connect_signal("property::selected",select_browser)
   end
end

-- * Signals
-- ** Signal function to execute when a new client appears.
focus_by_mouse = false

client.connect_signal("manage",
                  function (c, startup)
                     -- Add a titlebar
                     -- awful.titlebar.add(c, { modkey = modkey })

                     -- Enable sloppy focus
                     c:connect_signal("mouse::enter", function(c)
                                                     if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
                                                     and awful.client.focus.filter(c) then
                                                     client.focus = c
                                                     focus_by_mouse = true
                                                  end
                                               end)
                  end)

client.connect_signal("focus", function(c)
                              c.border_color = beautiful.border_focus
                              if not focus_by_mouse then
                                 c:raise()
                              else
                                 focus_by_mouse = false
                              end
                           end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- * autostart
-- awful.util.spawn("/usr/bin/nm-applet")

autostart = {
}

function mylauch(prgm)
   if not (prgm.hosts) or prgm.hosts[hostname] then
      cmd="start-stop-daemon --start --oknodo --background"
      if prgm.exec then
         cmd = cmd .. " --exec " .. prgm.exec
      end
      if prgm.name then
         cmd = cmd .. " --name " .. prgm.name
      end
      if prgm.startas then
         cmd = cmd .. " --startas " .. prgm.startas
      end
      if prgm.args then
         cmd = cmd .. " -- " .. prgm.args
      end
      awful.util.spawn(cmd)
      io.stderr:write('command: ')
      io.stderr:write(cmd)
      io.stderr:write('\n')
   end
end

for i, prgm in ipairs(autostart) do
   mylauch(prgm)
end
