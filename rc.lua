-- * Init

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- alt tab
local alttab = require("alttab")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local obvious = require("obvious")

local all_menu_dirs = { '/usr/share/applications/', '/usr/local/share/applications/', '~/.local/share/applications/', '/usr/share/applications/kde4/'}

menubar.menu_gen.all_menu_dirs = all_menu_dirs

-- Load Debian menu entries
require("debian.menu")

-- * Error handling
-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
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

-- * Some function definition
-- {{{ Some function definition
function match (table1, table2)
   for k, v in pairs(table1) do
      if not(table2[k]) or (table2[k] ~= v and not table2[k]:find(v)) then
         return false
      end
   end
   return true
end

-- Return clients matching a property
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
   if type(cmd) == "string" then
      awful.util.spawn(cmd)
   else
      cmd()
   end
end

-- raise or nothing
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

-- close a client if it exist.
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

-- }}}

-- * Variable definitions
-- {{{ Variable definitions
-- ** Session definition
-- hostname for host dependend configs
function hostname()
   local f = io.popen ("/bin/hostname")
   local n = f:read("*a") or "none"
   f:close()
   n=string.gsub(n, "\n$", "")
   return(n)
end

hostname = hostname()

session = {}

-- if false then                   -- systemd not for interactive session
--    session.name = "systemd"
-- else
--    session.name = "gnome"
-- end

session.name = "xsession"

if hostname == "gobelin" then
   hasbattery = true
else
   hasbattery = false
end

-- screen...

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

-- Themes define colours, icons, font and wallpapers.
beautiful.init("/home/moi/.config/awesome/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Some usefull program
if session.name == "systemd" then
   session.emacs = "systemctl --user start emacs.service"
   session.xbmc = "systemctl --user start xbmc.service"
   session.steam = "systemctl --user start steam.service"
   session.webbrowser = "systemctl --user start iceweasel.service"

   session.quit = function ()
      awful.util.spawn("systemctl --user start session-quit.service")
   end

   session.power_off = function ()
      awful.util.spawn("systemctl --user start poweroff.service")
   end

   session.reboot = function ()
      awful.util.spawn("systemctl --user start reboot.service")
   end

else                            -- other session 
   session.emacs = "emacs"
   session.xbmc = "xbmc"
   session.steam = "steam"
   session.webbrowser = "iceweasel"

   if session.name == "gnome" then
      session.quit = function ()
         awful.util.spawn("gnome-session-quit --logout") -- Do not seam to work...
      end

      session.power_off = function ()
         awful.util.spawn("gnome-session-quit --power-off")
      end

      session.reboot = function ()
         awful.util.spawn("gnome-session-quit --reboot")
      end
   else
      session.quit = function ()
         awesome.quit ()
      end

      session.power_off = function ()
         awful.util.spawn("systemctl poweroff")
      end

      session.reboot = function ()
         awful.util.spawn("systemctl reboot")
      end
   end
end

session.webbrowser_class = "Iceweasel"

session.filemanager = "nautilus -w"

session.quit_menu = { { "yes", session.quit },
   { "no", function () end },
   { "hibernate", session.hibernate },
   { "halt", session.power_off },
   { "reboot", session.reboot },
   { "restart", awesome.restart } }

if hostname == "madame" then
   table.insert(session.quit_menu,{ "hibernate to win", function () awful.util.spawn("gksudo /home/moi/bin/hibernate-to-win") end })
end

session.hibernate = function ()
   if hostname == "gobelin" then
      awful.util.spawn("dbus-send --print-reply --session --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock")
   end
   awful.util.spawn("dbus-send --print-reply --system --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower.Hibernate")
end

session.suspend = function ()
   if hostname == "gobelin" then
      awful.util.spawn("dbus-send --print-reply --session --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock")
   end
   awful.util.spawn("dbus-send --print-reply --system --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower.Suspend")
end



-- ** Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
spawnkey = { modkey, "Control" }

-- ** Layouts
-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    --- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    awful.layout.suit.floating
}
-- }}}

-- ** Wallpaper
-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- ** Tags
-- {{{ Tags
-- Define a tag table which hold all screen tags.
if hostname == "madame" then
   term_conf = { layout = awful.layout.suit.fair.horizontal, mfact = 0.5 }
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

tags_description = {
   {
      { name = "te", layout = term_conf },
      { name = "em", layout = full_conf },
      { name = "net", layout = full_conf },
      { name = "pl", layout = default_main_conf },
      { name = "fm", layout = default_main_conf },
      { name = "sup1", layout = float_conf },
      { name = "sup2", layout = float_conf },
   },
   {
      { name = "te", layout = default_second_conf },
      { name = "em", layout = full_conf },
      { name = "net", layout = full_conf },
      { name = "pl", layout = default_second_conf },
      { name = "fm", layout = default_second_conf },
      { name = "IM", layout = float_conf },
      { name = "cal", layout = default_second_conf}
   }
}

tags = {}
tags_by_name = {}
for s = 1, screen.count() do
   tags_by_name[s] = {}
   td = tags_description[s]
   -- Each screen has its own tag table.
   tags[s] = awful.tag({ td[1].name, td[2].name, td[3].name,
                         td[4].name, td[5].name, td[6].name,
                         td[7].name }, s, layouts[1])
   for i = 1, 7 do
      awful.layout.set(td[i].layout.layout,tags[s][i])
      tags_by_name[s][td[i].name]=tags[s][i]
   end
end
-- }}}

-- ** Menu
-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", session.quit_menu }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- * Wibox
-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
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
                                                                             { { "close", function ()
                                                                                             c:kill()
                                                                                             instance = nil
                                                                                          end, beautiful.titlebar_close_button_focus },
                                                                               { "maximize", function ()
                                                                                                c.maximized_horizontal = not c.maximized_horizontal
                                                                                                c.maximized_vertical = not c.maximized_vertical
                                                                                                instance = nil
                                                                                             end, max_icon },
                                                                               { "float", function ()
                                                                                             awful.client.floating.toggle(c)
                                                                                             instance = nil
                                                                                          end, float_icon },
                                                                               { "sticky", function ()
                                                                                              c.sticky=not c.sticky
                                                                                              instance = nil
                                                                                           end, sticky_icon },
                                                                               { "info", function ()
                                                                                            give_info(c)
                                                                                            instance = nil
                                                                                         end, nil },
                                                                               { "raise", function ()
                                                                                             c:raise()
                                                                                             instance = nil
                                                                                          end, nil },
                                                                               { "focus", function ()
                                                                                             awful.client.focus.byidx(0, c)
                                                                                             instance = nil
                                                                                          end, nil }}})
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
   else
      awful.util.spawn("setxkbmap \"" .. layout_string .. "\"")
   end
   update_keywidget()
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


keywidget_timer = timer({ timeout = 120 })
keywidget_timer:connect_signal("timeout", update_keywidget)
keywidget_timer:start()

-- ** Do create the wibox

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(keywidget) end
    if s == 1 then right_layout:add(wibox.widget.systray()) end

    if hasbattery then
       right_layout:add(obvious.battery())
    end
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- * Bindings

-- ** Mouse bindings
-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- ** Key bindings
-- {{{ Key bindings
-- some usefull function
function key_spawn (mod, key, cmd)
   if type(cmd) == "string" then
      return awful.key(mod, key, function () awful.util.spawn(cmd) end)
   else
      return awful.key(mod, key, function () cmd() end)
   end
end

function key_run_or_raise (mod, key, cmd, prop)
   return awful.key(mod, key, function () run_or_raise(cmd, prop) end)
end

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

-- the bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

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
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "s", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "t", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "s", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "t", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
       function ()
           alttab.switch(1, "Super_L", "Tab", "ISO_Left_Tab")
       end),
    awful.key({ modkey, "Shift"   }, "Tab",
       function ()
           alttab.switch(-1, "Super_L", "Tab", "ISO_Left_Tab")
       end),

    -- Standard program
    awful.key({ modkey, "Control" }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", function ()
                                            awful.menu(quit_menu):show({ keygrabber = true })
                                         end),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    -- awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "r", function() menubar.show() end),

    -- my change
    -- listing clients.
    awful.key({ modkey,           }, ",", function ()
                                            awful.menu.clients({}, { width = 250, keygrabber = true })
                                          end),
    -- multimedia
    key_spawn({}, "XF86PowerOff",         session.hibernate),
    key_spawn({}, "XF86AudioPlay",        "nyxmms2 toggle"),
    key_spawn({}, "XF86AudioStop",        "nyxmms2 stop"),

    key_spawn({}, "XF86AudioPrev",        "nyxmms2 prev"),
    key_spawn({}, "XF86AudioNext",        "nyxmms2 next"),

    key_spawn({ "Ctrl" }, "XF86AudioPlay",        "nyxmms2 stop"),
    key_spawn({ "Ctrl" }, "XF86AudioNext",        "xmms-rater 1; nyxmms2 next"),
    key_spawn({}, "XF86AudioRaiseVolume", "pactl set-sink-volume 0 +2%"),
    key_spawn({}, "XF86AudioLowerVolume", "pactl set-sink-volume 0 -2%"),
    key_spawn({}, "XF86AudioMute",        "amixer set Master toggle"),
    key_spawn({}, "XF86Sleep",            session.hibernate),

    key_spawn(spawnkey, "f",               session.filemanager),
    key_run_or_raise({}, "XF86AudioMedia", session.xbmc,                         { class = "xbmc.bin" }),
    key_run_or_raise({}, "XF86Tools",      session.xbmc,                         { class = "xbmc.bin" }),
    key_run_or_raise(spawnkey, "v",        "gnome-control-center sound", { class = "gnome-control-center" }),
    key_run_or_raise({}, "XF86HomePage",   session.webbrowser,                   { class = session.webbrowser_class }),
    key_run_or_raise(spawnkey, "w",        session.webbrowser,                   { class = session.webbrowser_class }),
    key_run_or_raise({}, "XF86Mail",       session.emacs,                        { class = "Emacs" }),
    key_run_or_raise(spawnkey, "e",        session.emacs,                        { class = "Emacs" }),
    key_run_or_raise({}, "XF86Launch7",    session.steam,                        { class = "Steam" })
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey,           }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
--    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- * Rules
-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
   -- All clients will match this rule.
   { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
   { rule = { class = "Run-calibre" },
     properties = { tag = tags_by_name[secondary_screen]["cal"] } },
   { rule = { class = "Calibre-gui", instance = "calibre-gui" },
     properties = { tag = tags_by_name[secondary_screen]["cal"] } },
   { rule = { class = "Iceweasel", instance = "Navigator" },
     properties = { tag = tags_by_name[main_screen]["net"] } },
   { rule = { class = "Chromium" },
     properties = { tag = tags_by_name[main_screen]["net"] } },
   { rule = { class = "Steam" },
     properties = { tag = tags_by_name[main_screen]["sup2"] } },
   { rule = { class = "MPlayer" },
     properties = { floating = true } },
   { rule = { class = "pinentry" },
     properties = { floating = true } },
   { rule = { class = "gimp" },
     properties = { floating = true } },
   { rule = { class = "Emacs" },
     properties = { tag = tags_by_name[main_screen]["em"],
                    size_hints_honor = false } },
   { rule = { class = "Miro.real"},
     properties = { tag = tags_by_name[main_screen]["pl"] } },
   { rule = { instance = "gajim.py" },
     properties = { tag = tags_by_name[secondary_screen]["IM"] } },
   { rule = { class = "Skype" },
     properties = { tag = tags_by_name[secondary_screen]["IM"] } },
   { rule = { class = "Transmission" },
     properties = { tag = tags_by_name[main_screen]["sup2"] } },
   { rule = { instance = "xmms-gtk-rater" },
     properties = { tag = tags_by_name[secondary_screen]["pl"] } },
   { rule = { instance = "cairo-dock" },
     properties = { ontop = true } },
   { rule = { instance = "cairo-dock" },
     properties = { ontop = true, focusable = false } },
   { rule = { instance = "abraca" },
     properties = { tag = tags_by_name[secondary_screen]["pl"] } },
   { rule = { class = "Pidgin" },
     properties = { tag = tags_by_name[secondary_screen]["IM"] } },
   { rule = { instance = "x-nautilus-desktop" },
     properties = { focusable = false } },

}
-- }}}

-- * Signals
-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- * Moving browser arround
-- {{{ Moving browser arround
function select_browser(tag)
   local clients = client.get()
   local properties = { class = session.webbrowser_class }

   if(tags_by_name[main_screen]["net"].selected) then
      ntag = tags_by_name[main_screen]["net"]
   elseif (tags_by_name[secondary_screen]["net"].selected) then
      ntag = tags_by_name[secondary_screen]["net"]
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
      tags_by_name[s]["net"]:connect_signal("property::selected",select_browser)
   end
end
-- }}}
