-- This is a QOL variable that lets you quickly change the codebase location
-- That is only if you export each of the libraries to a module, not require(id) it.
--local bin = script.Parent
--
--local sha1 = require(bin.sha1)
--local bit32 = require(bin.bit32)
--local basexx = require(bin.basexx)
--local util = require(bin.util)

--[[
	Authors:
		cody123454321 (Original)
		
	
	Credits to:
		https://github.com/kikito/sha.lua -- sha1
		http://www.snpedia.com/extensions/Scribunto/engines/LuaCommon/lualib/bit32.lua -- bit32
		https://github.com/pyotp/pyotp -- pyotp, which was brutally mutilated for the better to support Lua
		https://github.com/aiq/basexx -- for base32 algorithms in basexx
		https://github.com/Hydroque -- The original author of this module library
	
	Credits History:
		
	
	Tutorial:
	
	Terminology:
		 - OTP stands for One Time Password. TOTP stands for Timed OTP. HOTP stands for HMAC OTP.
		 - Counters are a number, which is supplied to HOTP, and pretty useless being anything else. When you
			use HOTP with Google Authenticator or Authy, they will increment the counter on their side that was
			supplied. You need to be cautious of these two values be desynchronized. However, they work perfectly
			fine without actually having the counter counting system - it works like vanilla OTP in where you can
			still compare the key the user is given with a key generated from the Base key.
		 - Base key is a personal keyword, which is just your random_base32() keyword used to make OTP. The data
			type for this will be called BASE32. It is a BASE32 format string. This will probably be referenced
			when 'key' is wrote. This is a SECRET key. If you give this key out it is now untrusted and can be
			iterated over for inqueries and can be used to find the current time key. Only transfer these over
			trusted tunnels.
		 - Auth key is the key the user gives you to verify against time in TOTP, or counters in HOTP. They
			are Strings here. They never get to you in the form of Number. They are aquired from regular OTP,
			and aren't specific to TOTP or HOTP. In fact, generate_otp() is the function.
		 - OTPURI used by Google Authenticator and Authy. It also is manditory for you to use to enable the QR code
			portion on Google Authenticator. It allows a phone camera to scan to register the secret code on the
			device.
		
	
		This module is pretty neat. It has cool features. In fact, you can't enjoy coding the features because
	they are already coded. This module works around inhertience. In order to accomplish this, when requiring,
	you should do a function call on the require as so: require(path)(). The function actually takes in a string.
	Also, the API is styled around static calls. This is why I kept otp.new(), so that you can create data packages.
	When it comes down to it, when you load functions to keys in a table instead of new functions to the keys. You
	should only make two calls to this require per script. The OTP object will create more functions that are present
	in other objects.
	
	
	First, what you want to do is go ahead and require the module and call it immediately and supply the string.
	What the string's value should be is the type of OTP you are going to use. The following are acceptable strings.
	Namely, you want to just supply OTP or otp if you aren't using HOTP or TOTP.
		> HOTP
		> hotp
		> TOTP
		> totp
		> OTP
		> otp
	
	When you choose HOTP or TOTP over the others, it actually builds off the base OTP API. Each HOTP and TOTP have
	very similarly named functions. However, they definitely will do different things. Below is a list of the API
	functions.
	
	format: return_type<Subtype> name(args)
	Subtype T means generic, or any Type
	> OTP
		ClassName<String> type
		OTP new(BASE32 secret, Number didgets=6, String digest="sha1")
		IntString generate_otp(OTP instance, String input)
		ByteString byte_secret(OTP instance)
		ByteString int_to_bytestring(Number i, Number padding=8)
	
	> TOTP
		AuthKey at(OTP instance, UNIXTime for_time, Number counter_offset=0)
		AuthKey now(OTP instance)
		Boolean verify(OTP instance, AuthKey key, UNIXTime for_time=os.time('utc'), Number valid_window=0)
		OTPURI as_uri(OTP instance, String name, String issuer_name)
		TimeCode timecode(OTP instance, UNIXTime for_time)
		
	> HOTP
		AuthKey at(OTP instance, Counter<Number> count)
		Boolean verify(OTP instance, AuthKey key, Counter<Number> counter)
		OTPURI as_uri(OTP instance, String name, Number initial_count=0, String issuer_name)
	
	This module holds required functions for OTP, HOTP, and TOTP to function...
		The only thing you should be touching is BASE32 random_base32()
	> util
		CharTable[] default_chars
		StringPattern base_uri
		BASE32 random_base32(Number length=16, CharTable[] chars=util.default_chars)
		URLARGS build_args(Dictionary<String, String> arr)
		OTPURI build_uri(BASE32 secret, String name, Number initial_count, String issuer_name, String algorithm, Number digits, Number period)
		Boolean strings_equal(String s1, String s2)
		Array<T> arr_reverse(Array<T> tab)
		ByteString byte_arr_tostring(ByteArray arr)
		ByteArray string_to_byte(String str)
		
	
	It is now time to go over the high-level things.
	
	TOTP's soul purpose is time event things. Such as, 'use this key before midnight for free Robux!'
		The AuthKeys you give users will expire. The BASE32 base key will have to generate a new one for
		a new set amount of time. However, you can unexpire a key, but that is insecure because it will
		allow people to have a great chance of randomly guessing a possible key in the future or past.
	HOTP's soul purpose is number based things. Such as, 'earn a number for a chance to win the lottery!'
		You will have to, and I mean have to, handle your own counter tracks. Each time you generate a key
		you should use this counter, then increment it afterwards. Not doing this will get out of sync
		with Authenticators. If using HOTP for lottery, then you wouldn't be used an authenticator and
		you will instead get a random range. In game lottery is fun.
	OTP's soul purpose is a one-time auth. It lacks anything. That's why you scrap your Base key after.
		However, if you so wish to hotlink crap, be my guest. The base key doesn't have to change. Although,
		I figure you would use HOTP for this, as I don't think people want to transfer.
	
	Do not use one key for OTP and TOTP/HOTP or for TOTP and HOTP. You can easily iterate and take a guess
	at the base key. However, someone has to be very adamant to find that base key. In TFA (two factor auth)
	where you use TOTP or HOTP to login, they would have to know the account credentials first. So thats
	the fesibility of that.
	
	https://github.com/pyotp/pyotp
	 ^ does a good job at showing the cause and effect of what this API does. It was built around it after all. I
		really think you should check out the readme.md... just scroll down the loaded page.
	
	Here is example scripts, utilizing the API.
	
	
	
	
	-- TOTP
	
	local OTP = require(game.Workspace.OTP)("TOTP") -- "totp" is accepted
	
	local _base_key = util.random_base32() -- you wouldn't use random keys for multiple sessions, as you couldn't auth anymore with the user
	local _timestamp = os.time('utc') -- the current time in seconds without decimals
	
	local data = OTP.new(_base_key, 6, "sha1", 30) -- 6 and "sha1" are constant because support issues with google authenticator
													-- however, 30secs is default and recommended the lasting time of the key
													-- you should note if you change the interval, ALL live keys break
	
		-- This is the user's end I.E. what the authenticator does for TOTP
		-- This has NOTHING to do with the above code.
	local now = OTP.now() -- this is a 6 digit Key the user gets from google authenticator or authy
	print(now) ~> 324123
	
		-- This is the server's end.
	local _ver = OTP.verify(data, now, _timestamp, 4) -- checks the users key 'now' to the seed _timestamp
																	-- around a specified time stamp, in this case
																	-- the last argument 4 is the amount of windows to check
																	-- so 30*4=120, which means +-120 seconds AuthKey alive time
	
	local _ver2 = OTP.verify(data, now+2, tostring(_timestamp), data.interval) -- modifying to invalidate
																				-- note keys are live for 30*30 in this one
	
		-- modifying either the timestamp or the key itself will mismatch them and do it's job in rejecting it
	print(_ver, _ver2) -> true false
	
	
	
	
	-- HOTP
	
	local OTP = require(game.ServerScriptService.OTP)("TOTP") -- "totp" is accepted
	
	local _base_key = util.random_base32()
	
	local data = OTP.new(_timestamp, 6, "sha1") -- no 30 because HOTP doesn't use intervals
	
	local gen1 = OTP.at(data, 25) -- two random number keys
	local gen2 = OTP.at(data, 50) -- can be any number
	print(gen1) ~> 821211
	print(gen2) ~> 002225
	
	local ver1 = OTP.verify(data, gen1, 25) -- does some 'backwards searching' to check if this key is correct
	local ver2 = OTP.verify(data, gen1, 50)
	local ver3 = OTP.verify(data, gen2, 25)
	local ver4 = OTP.verify(data, gen2, 50)
	
	print(ver1, ver2, ver3, ver4) -> true false false true
	
	
	
	Here is an example flow:
	-- TOTP
		> Server has a BASE32 key
		> User requests login
		> Server creates code for the current time
		> Server asks client for code
		> Client gives server code
		> Server checks the validity of code
		> Login or reject
	-- HOTP
		> Server has a BASE32 key
		> User requests login
		> Server creates code for the current counter, and increments it
		> Server asks client for code
		> Client generates a code with the proper counter, never if server and client are desynchronized
		> Client increments the counter
		> Client gives server code
		> Server checks the validity of code
		> Login or reject
	-- OTP
		> Server has a BASE32 key
		> User requests sign up
		> Server generates a code randomly and sends it via text
		> User checks email
		> Client inputs the code
		> Server checks the validity of code
		> Register complete or reject
	
	
	It is a little important to talk about QR codes. QR codes are the block blocks that contain URLs and stuff.
	http://www.qr-code-generator.com/
	 ^ here is a good site. Just slap in the URI that you need in order to generate your QR code. You can upload
		it to Roblox and use it. However, I find it is better to somehow come up with a QR code generator for GUIs.
		I don't think I am going to...
		
	Now about that URI that you need. HOTP and TOTP come with as_uri. It is very important that you mind what the
	different variables do. Google Authenticator's GITHUB has a full listing. They ignore some variables.
	https://github.com/google/google-authenticator/wiki/Key-Uri-Format
	 ^ Check it out
	
	I am just going to tell you what name, issuer name, and initial_count. Basically, you include the name in the
	URI so that Google Authenticator gives you the correct username listing, and the issuer name so we know who
	the code is from. HOTP you have to manually refresh - its not like TOTP. There are delays in the APP.
	initial_count is a variable that has to be set. I would just set it to OTP.at(data, 0). This is just a starter
	value. Their site says, REQUIRED if type is hotp: The counter parameter is required when provisioning a key for
	use with HOTP. It will set the initial counter value.
	
	Good luck. If you have any questions, contact me.
	
--]]

--==[[ Libraries ]]============================================================================

--==[[ basexx Library ]]======================================================================

local function number_to_bit( num, length )
    local bits = {}
 
    while num > 0 do
       local rest = math.floor( math.fmod( num, 2 ) )
       table.insert( bits, rest )
       num = ( num - rest ) / 2
    end
 
    while #bits < length do
       table.insert( bits, "0" )
    end
 
    return string.reverse( table.concat( bits ) )
 end
 
 local function ignore_set( str, set )
    if set then
       str = str:gsub( "["..set.."]", "" )
    end
    return str
 end
 
 local function pure_from_bit( str )
    return ( str:gsub( '........', function ( cc )
                return string.char( tonumber( cc, 2 ) )
             end ) )
 end
 
 local base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
 
 local function from_basexx( str, alphabet, bits )
    local result = {}
    for i = 1, #str do
       local c = string.sub( str, i, i )
       if c ~= '=' then
          local index = string.find( alphabet, c, 1, true )
          if not index then
             return nil, c
          end
          table.insert( result, number_to_bit( index - 1, bits ) )
       end
    end
 
    local value = table.concat( result )
    local pad = #value % 8
    return pure_from_bit( string.sub( value, 1, #value - pad ) )
 end
 
 
 local basexx = {}
 
 function basexx.from_base32( str, ignore )
    str = ignore_set( str, ignore )
    return from_basexx( string.upper( str ), base32Alphabet, 5 )
 end
 
 
 --==[[ bit32 Library ]]======================================================================
 
 ---
 -- An implementation of the lua 5.2 bit32 library, in pure Lua
 
 -- Note that in Lua, "x % n" is defined such that will always return a number
 -- between 0 and n-1 for positive n. We take advantage of that a lot here.
 
 local bit32 = {}
 
 local function checkint( name, argidx, x, level )
     local n = tonumber( x )
     if not n then
         error( string.format(
             "bad argument #%d to '%s' (number expected, got %s)",
             argidx, name, type( x )
         ), level + 1 )
     end
     return math.floor( n )
 end
 
 local function checkint32( name, argidx, x, level )
     local n = tonumber( x )
     if not n then
         error( string.format(
             "bad argument #%d to '%s' (number expected, got %s)",
             argidx, name, type( x )
         ), level + 1 )
     end
     return math.floor( n ) % 0x100000000
 end
 
 
 function bit32.bnot( x )
     x = checkint32( 'bnot', 1, x, 2 )
 
     -- In two's complement, -x = not(x) + 1
     -- So not(x) = -x - 1
     return ( -x - 1 ) % 0x100000000
 end
 
 
 ---
 -- Logic tables for and/or/xor. We do pairs of bits here as a tradeoff between
 -- table space and speed. If you change the number of bits, also change the
 -- constants 2 and 4 in comb() below, and the initial value in bit32.band and
 -- bit32.btest
 local logic_and = {
     [0] = { [0] = 0, 0, 0, 0},
     [1] = { [0] = 0, 1, 0, 1},
     [2] = { [0] = 0, 0, 2, 2},
     [3] = { [0] = 0, 1, 2, 3},
 }
 local logic_or = {
     [0] = { [0] = 0, 1, 2, 3},
     [1] = { [0] = 1, 1, 3, 3},
     [2] = { [0] = 2, 3, 2, 3},
     [3] = { [0] = 3, 3, 3, 3},
 }
 local logic_xor = {
     [0] = { [0] = 0, 1, 2, 3},
     [1] = { [0] = 1, 0, 3, 2},
     [2] = { [0] = 2, 3, 0, 1},
     [3] = { [0] = 3, 2, 1, 0},
 }
 
 ---
 -- @param name string Function name
 -- @param args table Function args
 -- @param nargs number Arg count
 -- @param s number Start value, 0-3
 -- @param t table Logic table
 -- @return number result
 local function comb( name, args, nargs, s, t )
     for i = 1, nargs do
         args[i] = checkint32( name, i, args[i], 3 )
     end
 
     local pow = 1
     local ret = 0
     for b = 0, 31, 2 do
         local c = s
         for i = 1, nargs do
             c = t[c][args[i] % 4]
             args[i] = math.floor( args[i] / 4 )
         end
         ret = ret + c * pow
         pow = pow * 4
     end
     return ret
 end
 
 function bit32.band( ... )
     return comb( 'band', { ... }, select( '#', ... ), 3, logic_and )
 end
 
 function bit32.bor( ... )
     return comb( 'bor', { ... }, select( '#', ... ), 0, logic_or )
 end
 
 function bit32.bxor( ... )
     return comb( 'bxor', { ... }, select( '#', ... ), 0, logic_xor )
 end
 
 function bit32.btest( ... )
     return comb( 'btest', { ... }, select( '#', ... ), 3, logic_and ) ~= 0
 end
 
 
 function bit32.extract( n, field, width )
     n = checkint32( 'extract', 1, n, 2 )
     field = checkint( 'extract', 2, field, 2 )
     width = checkint( 'extract', 3, width or 1, 2 )
     if field < 0 then
         error( "bad argument #2 to 'extract' (field cannot be negative)", 2 )
     end
     if width <= 0 then
         error( "bad argument #3 to 'extract' (width must be positive)", 2 )
     end
     if field + width > 32 then
         error( 'trying to access non-existent bits', 2 )
     end
 
     return math.floor( n / 2^field ) % 2^width
 end
 
 function bit32.replace( n, v, field, width )
     n = checkint32( 'replace', 1, n, 2 )
     v = checkint32( 'replace', 2, v, 2 )
     field = checkint( 'replace', 3, field, 2 )
     width = checkint( 'replace', 4, width or 1, 2 )
     if field < 0 then
         error( "bad argument #3 to 'replace' (field cannot be negative)", 2 )
     end
     if width <= 0 then
         error( "bad argument #4 to 'replace' (width must be positive)", 2 )
     end
     if field + width > 32 then
         error( 'trying to access non-existent bits', 2 )
     end
 
     local f = 2^field
     local w = 2^width
     local fw = f * w
     return ( n % f ) + ( v % w ) * f + math.floor( n / fw ) * fw
 end
 
 
 -- For the shifting functions, anything over 32 is the same as 32
 -- and limiting to 32 prevents overflow/underflow
 local function checkdisp( name, x )
     x = checkint( name, 2, x, 3 )
     return math.min( math.max( -32, x ), 32 )
 end
 
 function bit32.lshift( x, disp )
     x = checkint32( 'lshift', 1, x, 2 )
     disp = checkdisp( 'lshift', disp )
 
     return math.floor( x * 2^disp ) % 0x100000000
 end
 
 function bit32.rshift( x, disp )
     x = checkint32( 'rshift', 1, x, 2 )
     disp = checkdisp( 'rshift', disp )
 
     return math.floor( x / 2^disp ) % 0x100000000
 end
 
 function bit32.arshift( x, disp )
     x = checkint32( 'arshift', 1, x, 2 )
     disp = checkdisp( 'arshift', disp )
 
     if disp <= 0 then
         -- Non-positive displacement == left shift
         -- (since exponent is non-negative, the multipication can never result
         -- in a fractional part)
         return ( x * 2^-disp ) % 0x100000000
     elseif x < 0x80000000 then
         -- High bit is 0 == right shift
         -- (since exponent is positive, the division will never increase x)
         return math.floor( x / 2^disp )
     elseif disp > 31 then
         -- Shifting off all bits
         return 0xffffffff
     else
         -- 0x100000000 - 2 ^ ( 32 - disp ) creates a number with the high disp
         -- bits set. So shift right then add that number.
         return math.floor( x / 2^disp ) + ( 0x100000000 - 2 ^ ( 32 - disp ) )
     end
 end
 
 -- For the rotation functions, disp works mod 32.
 -- Note that lrotate( x, disp ) == rrotate( x, -disp ).
 function bit32.lrotate( x, disp )
     x = checkint32( 'lrotate', 1, x, 2 )
     disp = checkint( 'lrotate', 2, disp, 2 ) % 32
 
     local x = x * 2^disp
     return ( x % 0x100000000 ) + math.floor( x / 0x100000000 )
 end
 
 function bit32.rrotate( x, disp )
     x = checkint32( 'rrotate', 1, x, 2 )
     disp = -checkint( 'rrotate', 2, disp, 2 ) % 32
 
     local x = x * 2^disp
     return ( x % 0x100000000 ) + math.floor( x / 0x100000000 )
 end
 
 
 --==[[ SHA1 Library ]]======================================================================
 
 local sha1 = {
   _VERSION     = "sha.lua 0.5.0",
   _URL         = "https://github.com/kikito/sha.lua",
   _DESCRIPTION = [[
    SHA-1 secure hash computation, and HMAC-SHA1 signature computation in Lua (5.1)
    Based on code originally by Jeffrey Friedl (http://regex.info/blog/lua/sha1)
    And modified by Eike Decker - (http://cube3d.de/uploads/Main/sha1.txt)
   ]],
   _LICENSE = [[
     MIT LICENSE
     Copyright (c) 2013 Enrique García Cota + Eike Decker + Jeffrey Friedl
     Permission is hereby granted, free of charge, to any person obtaining a
     copy of this software and associated documentation files (the
     "Software"), to deal in the Software without restriction, including
     without limitation the rights to use, copy, modify, merge, publish,
     distribute, sublicense, and/or sell copies of the Software, and to
     permit persons to whom the Software is furnished to do so, subject to
     the following conditions:
     The above copyright notice and this permission notice shall be included
     in all copies or substantial portions of the Software.
     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
   ]]
 }
 
 
 -- loading this file (takes a while but grants a boost of factor 13)
 local PRELOAD_CACHE = true
 
 local BLOCK_SIZE = 64 -- 512 bits
 
 -- local storing of global functions (minor speedup)
 local floor,modf = math.floor,math.modf
 local char,format,rep = string.char,string.format,string.rep
 
 -- merge 4 bytes to an 32 bit word
 local function bytes_to_w32(a,b,c,d) return a*0x1000000+b*0x10000+c*0x100+d end
 -- split a 32 bit word into four 8 bit numbers
 local function w32_to_bytes(i)
   return floor(i/0x1000000)%0x100,floor(i/0x10000)%0x100,floor(i/0x100)%0x100,i%0x100
 end
 
 -- shift the bits of a 32 bit word. Don't use negative values for "bits"
 local function w32_rot(bits,a)
   local b2 = 2^(32-bits)
   local a,b = modf(a/b2)
   return a+b*b2*(2^(bits))
 end
 
 -- caching function for functions that accept 2 arguments, both of values between
 -- 0 and 255. The function to be cached is passed, all values are calculated
 -- during loading and a function is returned that returns the cached values (only)
 local function cache2arg(fn)
   if not PRELOAD_CACHE then return fn end
   local lut = {}
   for i=0,0xffff do
     local a,b = floor(i/0x100),i%0x100
     lut[i] = fn(a,b)
   end
   return function(a,b)
     return lut[a*0x100+b]
   end
 end
 
 -- splits an 8-bit number into 8 bits, returning all 8 bits as booleans
 local function byte_to_bits(b)
   local b = function(n)
     local b = floor(b/n)
     return b%2==1
   end
   return b(1),b(2),b(4),b(8),b(16),b(32),b(64),b(128)
 end
 
 -- builds an 8bit number from 8 booleans
 local function bits_to_byte(a,b,c,d,e,f,g,h)
   local function n(b,x) return b and x or 0 end
   return n(a,1)+n(b,2)+n(c,4)+n(d,8)+n(e,16)+n(f,32)+n(g,64)+n(h,128)
 end
 
 -- bitwise "and" function for 2 8bit number
 local band = cache2arg (function(a,b)
   local A,B,C,D,E,F,G,H = byte_to_bits(b)
   local a,b,c,d,e,f,g,h = byte_to_bits(a)
   return bits_to_byte(
     A and a, B and b, C and c, D and d,
     E and e, F and f, G and g, H and h)
 end)
 
 -- bitwise "or" function for 2 8bit numbers
 local bor = cache2arg(function(a,b)
   local A,B,C,D,E,F,G,H = byte_to_bits(b)
   local a,b,c,d,e,f,g,h = byte_to_bits(a)
   return bits_to_byte(
     A or a, B or b, C or c, D or d,
     E or e, F or f, G or g, H or h)
 end)
 
 -- bitwise "xor" function for 2 8bit numbers
 local bxor = cache2arg(function(a,b)
   local A,B,C,D,E,F,G,H = byte_to_bits(b)
   local a,b,c,d,e,f,g,h = byte_to_bits(a)
   return bits_to_byte(
     A ~= a, B ~= b, C ~= c, D ~= d,
     E ~= e, F ~= f, G ~= g, H ~= h)
 end)
 
 -- bitwise complement for one 8bit number
 local function bnot(x)
   return 255-(x % 256)
 end
 
 -- creates a function to combine to 32bit numbers using an 8bit combination function
 local function w32_comb(fn)
   return function(a,b)
     local aa,ab,ac,ad = w32_to_bytes(a)
     local ba,bb,bc,bd = w32_to_bytes(b)
     return bytes_to_w32(fn(aa,ba),fn(ab,bb),fn(ac,bc),fn(ad,bd))
   end
 end
 
 -- create functions for and, xor and or, all for 2 32bit numbers
 local w32_and = w32_comb(band)
 local w32_xor = w32_comb(bxor)
 local w32_or = w32_comb(bor)
 
 -- xor function that may receive a variable number of arguments
 local function w32_xor_n(a,...)
   local aa,ab,ac,ad = w32_to_bytes(a)
   for i=1,select('#',...) do
     local ba,bb,bc,bd = w32_to_bytes(select(i,...))
     aa,ab,ac,ad = bxor(aa,ba),bxor(ab,bb),bxor(ac,bc),bxor(ad,bd)
   end
   return bytes_to_w32(aa,ab,ac,ad)
 end
 
 -- combining 3 32bit numbers through binary "or" operation
 local function w32_or3(a,b,c)
   local aa,ab,ac,ad = w32_to_bytes(a)
   local ba,bb,bc,bd = w32_to_bytes(b)
   local ca,cb,cc,cd = w32_to_bytes(c)
   return bytes_to_w32(
     bor(aa,bor(ba,ca)), bor(ab,bor(bb,cb)), bor(ac,bor(bc,cc)), bor(ad,bor(bd,cd))
   )
 end
 
 -- binary complement for 32bit numbers
 local function w32_not(a)
   return 4294967295-(a % 4294967296)
 end
 
 -- adding 2 32bit numbers, cutting off the remainder on 33th bit
 local function w32_add(a,b) return (a+b) % 4294967296 end
 
 -- adding n 32bit numbers, cutting off the remainder (again)
 local function w32_add_n(a,...)
   for i=1,select('#',...) do
     a = (a+select(i,...)) % 4294967296
   end
   return a
 end
 -- converting the number to a hexadecimal string
 local function w32_to_hexstring(w) return format("%08x",w) end
 
 local function hex_to_binary(hex)
   return hex:gsub('..', function(hexval)
     return string.char(tonumber(hexval, 16))
   end)
 end
 
 -- building the lookuptables ahead of time (instead of littering the source code
 -- with precalculated values)
 local xor_with_0x5c = {}
 local xor_with_0x36 = {}
 for i=0,0xff do
   xor_with_0x5c[char(i)] = char(bxor(i,0x5c))
   xor_with_0x36[char(i)] = char(bxor(i,0x36))
 end
 
 
 -- calculating the SHA1 for some text
 function sha1.sha1(msg)
   local H0,H1,H2,H3,H4 = 0x67452301,0xEFCDAB89,0x98BADCFE,0x10325476,0xC3D2E1F0
   local msg_len_in_bits = #msg * 8
 
   local first_append = char(0x80) -- append a '1' bit plus seven '0' bits
 
   local non_zero_message_bytes = #msg +1 +8 -- the +1 is the appended bit 1, the +8 are for the final appended length
   local current_mod = non_zero_message_bytes % 64
   local second_append = current_mod>0 and rep(char(0), 64 - current_mod) or ""
 
   -- now to append the length as a 64-bit number.
   local B1, R1 = modf(msg_len_in_bits  / 0x01000000)
   local B2, R2 = modf( 0x01000000 * R1 / 0x00010000)
   local B3, R3 = modf( 0x00010000 * R2 / 0x00000100)
   local B4    = 0x00000100 * R3
 
   local L64 = char( 0) .. char( 0) .. char( 0) .. char( 0) -- high 32 bits
         .. char(B1) .. char(B2) .. char(B3) .. char(B4) --  low 32 bits
 
   msg = msg .. first_append .. second_append .. L64
 
   assert(#msg % 64 == 0)
 
   local chunks = #msg / 64
 
   local W = { }
   local start, A, B, C, D, E, f, K, TEMP
   local chunk = 0
 
   while chunk < chunks do
     --
     -- break chunk up into W[0] through W[15]
     --
     start,chunk = chunk * 64 + 1,chunk + 1
 
     for t = 0, 15 do
       W[t] = bytes_to_w32(msg:byte(start, start + 3))
       start = start + 4
     end
 
     --
     -- build W[16] through W[79]
     --
     for t = 16, 79 do
       -- For t = 16 to 79 let Wt = S1(Wt-3 XOR Wt-8 XOR Wt-14 XOR Wt-16).
       W[t] = w32_rot(1, w32_xor_n(W[t-3], W[t-8], W[t-14], W[t-16]))
     end
 
     A,B,C,D,E = H0,H1,H2,H3,H4
 
     for t = 0, 79 do
       if t <= 19 then
         -- (B AND C) OR ((NOT B) AND D)
         f = w32_or(w32_and(B, C), w32_and(w32_not(B), D))
         K = 0x5A827999
       elseif t <= 39 then
         -- B XOR C XOR D
         f = w32_xor_n(B, C, D)
         K = 0x6ED9EBA1
       elseif t <= 59 then
         -- (B AND C) OR (B AND D) OR (C AND D
         f = w32_or3(w32_and(B, C), w32_and(B, D), w32_and(C, D))
         K = 0x8F1BBCDC
       else
         -- B XOR C XOR D
         f = w32_xor_n(B, C, D)
         K = 0xCA62C1D6
       end
 
       -- TEMP = S5(A) + ft(B,C,D) + E + Wt + Kt;
       A,B,C,D,E = w32_add_n(w32_rot(5, A), f, E, W[t], K),
         A, w32_rot(30, B), C, D
     end
     -- Let H0 = H0 + A, H1 = H1 + B, H2 = H2 + C, H3 = H3 + D, H4 = H4 + E.
     H0,H1,H2,H3,H4 = w32_add(H0, A),w32_add(H1, B),w32_add(H2, C),w32_add(H3, D),w32_add(H4, E)
   end
   local f = w32_to_hexstring
   return f(H0) .. f(H1) .. f(H2) .. f(H3) .. f(H4)
 end
 
 
 function sha1.binary(msg)
   return hex_to_binary(sha1.sha1(msg))
 end
 
 function sha1.hmac(key, text)
   assert(type(key)  == 'string', "key passed to sha1.hmac should be a string")
   assert(type(text) == 'string', "text passed to sha1.hmac should be a string")
 
   if #key > BLOCK_SIZE then
     key = sha1.binary(key)
   end
 
   local key_xord_with_0x36 = key:gsub('.', xor_with_0x36) .. string.rep(string.char(0x36), BLOCK_SIZE - #key)
   local key_xord_with_0x5c = key:gsub('.', xor_with_0x5c) .. string.rep(string.char(0x5c), BLOCK_SIZE - #key)
 
   return sha1.sha1(key_xord_with_0x5c .. sha1.binary(key_xord_with_0x36 .. text))
 end
 
 function sha1.hmac_binary(key, text)
   return hex_to_binary(sha1.hmac(key, text))
 end
 
 setmetatable(sha1, {__call = function(_,msg) return sha1.sha1(msg) end })
 
 
 
 --==[[ Util Library ]]======================================================================
 
 local util = {}
 
 util.default_chars = {
     'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
     'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
     'U', 'V', 'W', 'X', 'Y', 'Z', '2', '3', '4', '5',
     '6', '7'
 }
 
 util.base_uri = "otpauth://%s/%s%s"
 
 util.random_base32 = function(length, chars)
     length = length or 16
     chars = chars or util.default_chars
     local out = ""
     for i=1, length do
         out = out .. chars[math.random(1, #chars)]
     end
     return out
 end
 
 util.build_args = function(arr)
     local out = "?"
     for i, v in pairs(arr)do
         out = out .. i .. '=' .. util.encode_url(v) .. '&'
     end
     return string.sub(out, 1, #out-1)
 end
 
 util.encode_url = function(url, protocol)
     local out = ""
     if type(url) ~= "string" then
         url = textutils.serialize(url)
     end
     for i=1, #url do
         local char = url:sub(i,i)
         local byte = string.byte(char)
         local ch = string.gsub(char, "^[%c\"<>#%%%s{}|\\%^~%[%]`]+", function(s)
             return string.format("%%%02x", byte)
         end)
         if(byte > 126)then
             ch = string.format("%%%02x", byte)
         end
         out = out .. ch
     end
     return (protocol or "") .. out
 end
 
 util.build_uri = function(secret, name, initial_count, issuer_name, algorithm, digits, period)
     local is_init_set = initial_count ~= nil
     
     local is_algo_set = (algorithm ~= nil) and algorithm ~= "SHA1"
     local is_digi_set = digits ~= nil
     local is_peri_set = period ~= nil
     
     local otp_type = is_init_set and "hotp" or "totp"
     
     local label = util.encode_url(name)
     
     if (issuer_name ~= nil) then
         label = util.encode_url(issuer_name) .. ':' .. label
     end
     if(is_algo_set)then
         algorithm = string.upper(algorithm)
     end
     local url_args = {
         secret = secret,
         issuer = issuer_name,
         counter = initial_count,
         algorithm = algorithm,
         digits = digits,
         period = period
     }
     return string.format(util.base_uri, otp_type, label, util.build_args(url_args))
 end
 
 util.strings_equal = function(s1, s2)
     local matches = true
     for i=1, #s1 do
         if(s1:sub(i,i) ~= s2:sub(i,i))then
             matches = false
             break
         end
     end
     return matches
 end
 
 util.arr_reverse = function(tab)
     local out = {}
     for i=1, #tab do
         out[i] = tab[1+#tab - i]
     end
     return out
 end
 
 util.byte_arr_tostring = function(arr)
     local out = ""
     for i=1, #arr do
         out = out .. string.char(arr[i])
     end
     return out
 end
 
 util.str_to_byte = function(str)
     local out = {}
     for i=1, #str do
         out[i] = string.byte(str:sub(i,i))
     end
     return out
 end
 
 
 --==[[ Actual Source ]]======================================================================
 
 local otp = {}
 otp.type = nil
 
 --[[
     {...} contains:
         otp.type == totp
             > Number interval
             
         otp.type == hotp
             > nil
             
         otp.type == otp
             > nil
 --]]
 otp.new = function(secret, digits, digest, ...)
     local this = {}
     this.secret = secret
     this.digits = digits or 6
     this.digest = digest or "sha1"
     
     local args = {...}
     if(string.lower(otp.type) == "totp")then
         this.interval = args[1]
     elseif(string.lower(otp.type) == "hotp")then
         
     end
     
     return this
 end
 
 
 
 otp.generate_otp = function(instance, input)
     local hash = sha1.hmac_binary(otp.byte_secret(instance), otp.int_to_bytestring(input))
     local offset = bit32.band(string.byte(hash:sub(-1, -1)), 0xF) + 1
     
     local bhash = util.str_to_byte(hash)
     
     local code = bit32.bor(
         bit32.lshift(bit32.band(bhash[offset], 0x7F), 24),
         bit32.lshift(bit32.band(bhash[offset + 1], 0xFF), 16),
         bit32.lshift(bit32.band(bhash[offset + 2], 0xFF), 8),
         bit32.lshift(bit32.band(bhash[offset + 3], 0xFF), 0)
     )
     
     local str_code = tostring(code % math.pow(10, instance.digits))
     while #str_code < instance.digits do
         str_code = '0' .. str_code
     end
     
     return str_code
 end
 
 otp.byte_secret = function(instance)
     local missing_padding = #instance.secret % 8
     if (missing_padding ~= 0) then
         instance.secret = instance.secret .. string.rep('=', (8 - missing_padding))
     end
     return basexx.from_base32(instance.secret)
 end
 
 otp.int_to_bytestring = function(i, padding)
     padding = padding or 8
     local bytes = {}
     while (i ~= 0) do
         table.insert(bytes, bit32.band(i, 0xFF))
         i = bit32.rshift(i, 8)
     end
     return string.rep('\0', math.max(0, padding - #bytes)) .. util.byte_arr_tostring(util.arr_reverse(bytes))
 end
 
 
 
 local totp = {}
 
 totp.at = function(instance, for_time, counter_offset)
     counter_offset = counter_offset or 0
     for_time = for_time + 5
     if (for_time == nil) then
         error("No for_time supplied.")
     end
     return otp.generate_otp(instance, totp.timecode(instance, tonumber(for_time)) + counter_offset)
 end
 
 totp.now = function(instance)
     return otp.generate_otp(instance, totp.timecode(instance, os.time('utc')))
 end
 
 totp.verify = function(instance, key, for_time, valid_window)
     valid_window = valid_window or 0
     
     if (for_time == nil) then
         for_time = os.time('utc')
     end
     
     if (valid_window > 0) then
         for i=-valid_window, valid_window, 1 do
             if (util.strings_equal(tostring(key), tostring(totp.at(instance, for_time, i)))) then
                 return true
             end
         end
         return false
     end
     return util.strings_equal(tostring(key), tostring(totp.at(instance, for_time)))
 end
 
 totp.as_uri = function(instance, name, issuer_name)
     issuer_name = issuer_name or nil
     return util.build_uri(instance.secret, name, nil, issuer_name, instance.digest, instance.digits, instance.interval)
 end
 
 totp.timecode = function(instance, for_time)
     return math.floor(for_time/instance.interval)
 end
 
 
 
 local hotp = {}
 
 hotp.at = function(instance, count)
     return otp.generate_otp(instance, count)
 end
 
 hotp.verify = function(instance, key, counter)
     return util.strings_equal(key, hotp.at(instance, counter))
 end
 
 hotp.as_uri = function(instance, name, initial_count, issuer_name)
     initial_count = initial_count or 0
     return util.build_uri(instance.secret, name, initial_count, issuer_name, instance.digest, instance.digits)
 end
 
 --==[[ Modular Return ]]======================================================================
 
 return function(str)
     if (str == "totp" or str == "TOTP") then
         otp["type"] = str
         for i, v in pairs(totp)do
             otp[i] = v
         end
         return otp
     elseif (str == "hotp" or str == "HOTP") then
         otp["type"] = str
         for i, v in pairs(hotp)do
             otp[i] = v
         end
         return hotp
     elseif (str == "util" or str == "UTIL" or str == "utils" or str == "UTILS") then
        return util
     elseif (str == "sha1" or str == "SHA1") then
        return sha1
     else
         otp["type"] = "otp"
         return otp
     end
 end
