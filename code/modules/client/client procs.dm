	////////////
	//SECURITY//
	////////////
#define TOPIC_SPAM_DELAY	2		//2 ticks is about 2/10ths of a second; it was 4 ticks, but that caused too many clicks to be lost due to lag
#define UPLOAD_LIMIT		6291456	//Restricts client uploads to the server to 6MB.
#define MIN_CLIENT_VERSION	0		//Just an ambiguously low version for now, I don't want to suddenly stop people playing.
									//I would just like the code ready should it ever need to be used.
	/*
	When somebody clicks a link in game, this Topic is called first.
	It does the stuff in this proc and  then is redirected to the Topic() proc for the src=[0xWhatever]
	(if specified in the link). ie locate(hsrc).Topic()

	Such links can be spoofed.

	Because of this certain things MUST be considered whenever adding a Topic() for something:
		- Can it be fed harmful values which could cause runtimes?
		- Is the Topic call an admin-only thing?
		- If so, does it have checks to see if the person who called it (usr.client) is an admin?
		- Are the processes being called by Topic() particularly laggy?
		- If so, is there any protection against somebody spam-clicking a link?
	If you have any  questions about this stuff feel free to ask. ~Carn
	*/

var/global/max_players = 40

/client/Topic(href, href_list, hsrc)
	if(!usr || usr != mob)	//stops us calling Topic for somebody else's client. Also helps prevent usr=null
		return

	//Reduces spamming of links by dropping calls that happen during the delay period
	if(next_allowed_topic_time > world.time)
		return
	next_allowed_topic_time = world.time + TOPIC_SPAM_DELAY

	//search the href for script injection
	if( findtext(href,"<script",1,0) )
		world.log << "Attempted use of scripts within a topic call, by [src]"
		message_admins("Attempted use of scripts within a topic call, by [src]")
		//del(usr)
		return

	// LISTA DE ACHIEVEMENTS
	if(href_list["achievements"])
		var/client/C = locate(href_list["achievements"])
		if(ismob(C))
			var/mob/M = C
			C = M.client
		show_medal(ckeychecking = "[C.ckey]")
		return
	//Admin PM
	if(href_list["priv_msg"])
		var/client/C = locate(href_list["priv_msg"])
		if(ismob(C)) 		//Old stuff can feed-in mobs instead of clients
			var/mob/M = C
			C = M.client
		cmd_admin_pm(C,null)
		return
	if(href_list["_src_"] == "stat")
		if(href_list["spload"] == "1")
			statpanel_loaded = TRUE
			init_panel()
		if(href_list["modernbrowser"] == "1")
			statpanel_loaded = TRUE
		if(href_list["buttonpig"] == "1")
			src << 'sound/uibutton.ogg'
			who()
		if(href_list["buttonchrome"] == "1")
			src << 'sound/uibutton.ogg'
			if(current_button == "chrome")
				return
			current_button = "chrome"
			newtext(html_verbs[current_button])
		if(href_list["buttonoptions"] == "1")
			src << 'sound/uibutton.ogg'
			if(current_button == "options")
				return
			current_button = "options"
			newtext(html_verbs[current_button])
		if(href_list["buttonnote"] == "1")
			src << 'sound/uibutton.ogg'
			if(current_button == "note")
				return
			current_button = "note"
			newtext(mob.noteUpdate())
		if(href_list["buttondynamic"])
			src << 'sound/uibutton.ogg'
			if(current_button == href_list["buttondynamic"])
				return
			current_button = href_list["buttondynamic"]
			newtext(html_verbs[current_button])



	//Logs all hrefs
	if(config && config.log_hrefs && href_logfile)
		href_logfile << "<small>[time2text(world.timeofday,"hh:mm")] [src] (usr:[usr])</small> || [hsrc ? "[hsrc] " : ""][href]<br>"

	switch(href_list["_src_"])
		if("holder")	hsrc = holder
		if("usr")		hsrc = mob
		if("prefs")		return prefs.process_link(usr,href_list)
		if("vars")		return view_var_Topic(href,href_list,hsrc)
		if("chat")		return chatOutput.Topic(href, href_list)


	..()	//redirect to hsrc.Topic()

/client/proc/handle_spam_prevention(var/message, var/mute_type)
	if(config.automute_on && !holder && src.last_message == message)
		src.last_message_count++
		if(src.last_message_count >= SPAM_TRIGGER_AUTOMUTE)
			src << "\red You have exceeded the spam d_filter limit for identical messages. An auto-mute was applied."
			cmd_admin_mute(src.mob, mute_type, 1)
			return 1
		if(src.last_message_count >= SPAM_TRIGGER_WARNING)
			src << "\red You are nearing the spam d_filter limit for identical messages."
			return 0
	else
		last_message = message
		src.last_message_count = 0
		return 0

//This stops files larger than UPLOAD_LIMIT being sent from client to server via input(), client.Import() etc.
/client/AllowUpload(filename, filelength)
	if(filelength > UPLOAD_LIMIT)
		src << "<font color='red'>Error: AllowUpload(): File Upload too large. Upload Limit: [UPLOAD_LIMIT/1024]KiB.</font>"
		return 0
/*	//Don't need this at the moment. But it's here if it's needed later.
	//Helps prevent multiple files being uploaded at once. Or right after eachother.
	var/time_to_wait = fileaccess_timer - world.time
	if(time_to_wait > 0)
		src << "<font color='red'>Error: AllowUpload(): Spam prevention. Please wait [round(time_to_wait/10)] seconds.</font>"
		return 0
	fileaccess_timer = world.time + FTPDELAY	*/
	return 1


	///////////
	//CONNECT//
	///////////
/client/New(TopicData)
	TopicData = null							//Prevent calls to client.Topic from connect

	// CARREGAR GOONCHAT
	if(connection != "seeker")					//Invalid connection type.]
		return null
	if(byond_build < 1556 || byond_version < 514)		//Out of date client.
		src << link("https://wiki.nearweb.org/images/0/0a/Byond_young.png")
		del(src)
		return

	/*(if(IsGuestKey(key))
		alert(src,"This server doesn't allow guest accounts to play. Please go to http://www.byond.com/ and register for a key.","Guest","OK")
		qdel(src)
		return*/
	///////////////////////
	//DETECTOR DE GRINGOS//
	///////////////////////
#ifdef NEARWEB_LIVE
	if(!IsGuestKey(key))
		var/list/locinfo = get_loc_info()
		if(!Country_Code)
			Country_Code = locinfo["country_code"]

	if(ckey in bans)
		src << link("https://wiki.nearweb.org/images/0/06/Lifeweb_completed.png")
		del(src)
		return

	if(clients.len >= max_players && !holder)
		src << link("https://wiki.nearweb.org/images/0/00/Pool_overpop.png")
		qdel(src)
		return
	if(!JoinDate)
		var/list/http[] = world.Export("http://www.byond.com/members/[src.ckey]?format=text")
		var/Joined = 0000-00-00
		if(http && http.len && ("CONTENT" in http))
			var/String = file2text(http["CONTENT"])
			var/JoinPos = findtext(String, "joined")+10
			Joined = copytext(String, JoinPos, JoinPos+10)
			src.JoinDate = Joined

	switch(private_party)
		if(TRUE)
			if((!ckeywhitelistweb.Find(src.ckey)))
				notInvited()
				return
		if(FALSE)
			if(!ckeywhitelistweb.Find(src.ckey) && text2num(copytext(src.JoinDate, 1, 5)) >= 2026)
				notInvited()
				return

	// Change the way they should download resources.
	//src.preload_rsc = "https://www.dropbox.com/s/kfe9yimm9oi2ooj/MACACHKA.zip?dl=1"
#endif
	statpanel_loaded = FALSE
	chatOutput = new /datum/chatOutput(src)
	to_chat(src, "<span class='highlighttext'> If your screen is dark and you can't interact with the menu, just wait. You must be downloading resources..</span>")
	to_chat(src, "<span class='highlighttext'>\n If the stat panel fails to load, press F5 while your mouse is over it.</span>")
	clients += src
	directory[ckey] = src
	src << browse({"<meta http-equiv="X-UA-Compatible" content="IE=edge"><script>function post(url, data) {if(!url) return;var http = new XMLHttpRequest;http.open('POST', url);http.setRequestHeader('Content-Type', 'application/json');http.send(data);}</script>"}, "window=http_post_browser")
	winshow(src, "http_post_browser", FALSE)
	if(src.key in lord)
		src.verbs += /client/proc/toggle_hand

	//Admin Authorisation
	holder = admin_datums[ckey]
	if(holder)
		admins += src
		holder.owner = src

	//preferences datum - also holds some persistant data for the client (because we may as well keep these datums to a minimum)
	prefs = preferences_datums[ckey]
	fps = 67
	if(!prefs)
		prefs = new /datum/preferences(src)
		preferences_datums[ckey] = prefs
	prefs.last_ip = address				//these are gonna be used for banning
	prefs.last_id = computer_id			//these are gonna be used for banning
	if(prefs.rsc_fix)
		src.preload_rsc = prefs.rsc_fix
	else
		src.preload_rsc = 1
	winset(src, "mapwindow.map", "zoom=[prefs.zoom_level];")

#ifdef NEARWEB_LIVE
	info = dbdatums[ckey]
	if(!info)
		info = new /datum/dbinfo(src)
		dbdatums[ckey] = info
#endif


	. = ..()	//calls mob.Login()

	if( (world.address == address || !address) && !host )
		host = key
		world.update_status()

	if(holder)
		add_admin_verbs()
		admin_memo_show()

	send_resources()

	if(prefs.lastchangelog != changelog_hash) //bolds the changelog button on the interface so we know there are updates.
		winset(src, "rpane.changelog", "background-color=#eaeaea;font-style=bold")
	fit_viewport()
	winshow(src, "http_post_browser", FALSE)

#ifdef NEARWEB_LIVE
	if(authenticated)
		chatOutput.start()
#else
	chatOutput.start()
#endif
	ambience_playing = FALSE

	//////////////
	//DISCONNECT//
	//////////////
/client/Del()
	if(holder)
		holder.owner = null
		admins -= src
	directory -= ckey
	clients -= src
	authenticated = FALSE
	return ..()

/client/var/toggle_hand
/client/proc/toggle_hand()
	set hidden = 0
	set category = "Lord"
	set name = "Choose Lord Hand"
	set desc="Choose your hand!"
	var/list/keys = list()
	for(var/mob/new_player/M in player_list)
		if(M != src.mob)
			keys += M.client.prefs.real_name
	var/selection = input("Select your Hand!", "Lord Hand", null, null) as null|anything in keys
	if(!selection)
		return
	var/mob/M = selection
	if(M.client.toggle_hand)
		to_chat(src, "<b>[selection]</b> <font color='red'> teve o convite cancelado.</font>")
		to_chat(M, "<b>[src]</b> <font color='red'> não quer mais você como hand.</font>")
		M.client.toggle_hand = FALSE
		return
	else
		to_chat(src, "<b>[selection]</b> <font color='red'> foi convidado para ser seu hand.</font>")
		to_chat(M, "<b>[src]</b> <font color='red'> te escolheu para ser o hand dele, entre de migrante para se juntar ao lorde!</font>")
		M.client.toggle_hand = TRUE
		return

#undef TOPIC_SPAM_DELAY
#undef UPLOAD_LIMIT
#undef MIN_CLIENT_VERSION

//checks if a client is afk
//3000 frames = 5 minutes
/client/proc/is_afk(duration=3000)
	if(inactivity > duration)	return inactivity
	return 0

//send resources to the client. It's here in its own proc so we can move it around easiliy if need be
/client/proc/send_resources()
	// Send NanoUI resources to this client
	nanomanager.send_resources(src)

	getFiles(
		'html/painew.png',
		'html/loading.gif',
		'html/search.js',
		'html/panels.css',
		'sound/music/OS13_combat.ogg',
		'sound/music/haruspex-combat.ogg',
		'sound/music/OS13_combat.ogg',
		'sound/music/ravenheart_combat1.ogg',
		'sound/lfwbsounds/bloodlust1.ogg',
		'sound/fortress_suspense/suspense1.ogg',
		'sound/fortress_suspense/suspense2.ogg',
		'sound/fortress_suspense/suspense3.ogg',
		'sound/fortress_suspense/suspense4.ogg',
		'sound/fortress_suspense/suspense5.ogg',
		'sound/fortress_suspense/suspense6.ogg',
		'sound/fortress_suspense/suspense7.ogg',
		'sound/fortress_suspense/suspense8.ogg',
		'sound/fortress_suspense/suspense_thanati.ogg',
		'sound/fortress_suspense/suspense_xom.ogg'
		)

/client/proc/GetHighJob()
	if(master_mode == "minimig" || master_mode == "miniwar")
		return
	if(src.prefs.job_civilian_high)
		switch(src.prefs.job_civilian_high)
			if(HOP)
				work_chosen = "Meister"
			if(BARTENDER)
				work_chosen = "Bartender"
			if(BOTANIST)
				work_chosen = "Soiler"
			if(JANITOR)
				work_chosen = "Misero"
			if(QUARTERMASTER)
				work_chosen = "Merchant"
			if(CARGOTECH)
				work_chosen = "Docker"
			if(ENGINEER)
				work_chosen = "Wright"
			if(LAWYER)
				work_chosen = "Magistrate"
			if(CLOWN)
				work_chosen = "Jester"
			if(HOOKER)
				work_chosen = "Amuser"
			if(SMUGGLER)
				work_chosen = "Pusher"
			if(HOBO)
				work_chosen = "Bum"
			if(APPRENTICE)
				work_chosen = "Apprentice"
			if(SERVANT)
				work_chosen = "Servant"
			if(MIGRANT)
				work_chosen = "Migrant"
			if(MORTUS)
				work_chosen = "Mortus"
			if(SITZFRAU)
				work_chosen = "Sitzfrau"
			if(BUTLER)
				work_chosen = "Butler"
			if(SNIFFER)
				work_chosen = "Bum"
			if(CONSYTE)
				work_chosen = "Consyte"
	else if(src.prefs.job_medsci_high)
		switch(src.prefs.job_medsci_high)
			if(RD)
				work_chosen = "Research Director"
			if(MERC)
				work_chosen = "Mercenary"
			if(URCHIN)
				work_chosen = "Urchin"
			if(SCIENTIST)
				work_chosen = "Scientist"
			if(CMO)
				work_chosen = "Esculap"
			if(DOCTOR)
				work_chosen = "Serpent"
			if(CHEMSIS)
				work_chosen = "Chemsister"
			if(ARMORSMITH)
				work_chosen = "Blacksmith’s Assistant"
			if(METALSMITH)
				work_chosen = "Blacksmith"
			if(GENETICIST)
				work_chosen = "Counselor"
			if(CONSYTE)
				work_chosen = "Consyte"
			if(INNKEEPERWIFE)
				work_chosen = "Madam"
			if(GUEST)
				work_chosen = "Guest"
			if(TRIBVET)
				work_chosen = "Tribunal Veteran"
			if(SCUFF)
				work_chosen = "Scuff"
			if(FACKID)
				work_chosen = "Minor Worker"
			if(HAG)
				work_chosen = "Fortune Teller"
			if(GANGER)
				work_chosen = "Ganger"
			if(CHEF)
				work_chosen = "Boozehound"
	else if(src.prefs.job_engsec_high)
		switch(src.prefs.job_engsec_high)
			if(CAPTAIN)
				work_chosen = "Baron"
			if(GATEKEEPER)
				work_chosen = "Charybdis"
			if(HAND)
				work_chosen = "Hand"
			if(HEIR)
				work_chosen = "Heir"
			if(HOS)
				work_chosen = "Kraken"
			if(WARDEN)
				work_chosen = "Warden"
			if(CHAPLAIN)
				work_chosen = "Vicar"
			if(DETECTIVE)
				work_chosen = "Detective"
			if(OFFICER)
				work_chosen = "Triton"
			if(CHIEF)
				work_chosen = "Engineer"
			if(ENGINEER)
				work_chosen = "Wright"
			if(ATMOSTECH)
				work_chosen = "Atmospheric Technician"
			if(AI)
				work_chosen = "AI"
			if(CYBORG)
				work_chosen = "Cyborg"
			if(SUCCESSOR)
				work_chosen = "Successor"
			if(SHERIFF)
				work_chosen = "Sheriff"
			if(SQUIRE)
				work_chosen = "Squire"
			if(HEIR)
				work_chosen = "Heir"
			if(BARONESS)
				work_chosen = "Baroness"
			if(MAID)
				work_chosen = "Maid"
			if(NUN)
				work_chosen = "Nun"
			if(MEISTERDISC)
				work_chosen = "Treasurer"
			if(PRACTICUS)
				work_chosen = "Sniffer"
			if(BGUARD)
				work_chosen = "Court Bodyguard"
			if(INQUISITOR)
				work_chosen = "Praetor"
			if(CONSYTE)
				work_chosen = "Consyte"
	else
		if(src.prefs.job_civilian_med)
			switch(src.prefs.job_civilian_med)
				if(HOP)
					work_chosen = "Meister"
				if(BARTENDER)
					work_chosen = "Bartender"
				if(BOTANIST)
					work_chosen = "Soiler"
				if(JANITOR)
					work_chosen = "Misero"
				if(QUARTERMASTER)
					work_chosen = "Merchant"
				if(CARGOTECH)
					work_chosen = "Docker"
				if(ENGINEER)
					work_chosen = "Wright"
				if(LAWYER)
					work_chosen = "Magistrate"
				if(CLOWN)
					work_chosen = "Jester"
				if(HOOKER)
					work_chosen = "Amuser"
				if(SMUGGLER)
					work_chosen = "Pusher"
				if(HOBO)
					work_chosen = "Bum"
				if(APPRENTICE)
					work_chosen = "Apprentice"
				if(SERVANT)
					work_chosen = "Servant"
				if(MIGRANT)
					work_chosen = "Migrant"
				if(MORTUS)
					work_chosen = "Mortus"
				if(SITZFRAU)
					work_chosen = "Sitzfrau"
				if(BUTLER)
					work_chosen = "Butler"
				if(SNIFFER)
					work_chosen = "Bum"
				if(CONSYTE)
					work_chosen = "Consyte"
				if(SCUFF)
					work_chosen = "Scuff"
				if(FACKID)
					work_chosen = "Minor Worker"
				if(HAG)
					work_chosen = "Fortune Teller"
				if(GANGER)
					work_chosen = "Ganger"
				if(CHEF)
					work_chosen = "Boozehound"
		else if(src.prefs.job_medsci_med)
			switch(src.prefs.job_medsci_med)
				if(RD)
					work_chosen = "Research Director"
				if(SCIENTIST)
					work_chosen = "Scientist"
				if(CMO)
					work_chosen = "Esculap"
				if(METALSMITH)
					work_chosen = "Blacksmith"
				if(CHEMSIS)
					work_chosen = "Chemsister"
				if(ARMORSMITH)
					work_chosen = "Blacksmith’s Assistant"
				if(DOCTOR)
					work_chosen = "Serpent"
				if(GENETICIST)
					work_chosen = "Counselor"
				if(MERC)
					work_chosen = "Mercenary"
				if(URCHIN)
					work_chosen = "Urchin"
				if(CONSYTE)
					work_chosen = "Consyte"
				if(INNKEEPERWIFE)
					work_chosen = "Madam"
				if(GUEST)
					work_chosen = "Guest"
				if(TRIBVET)
					work_chosen = "Tribunal Veteran"
		else if(src.prefs.job_engsec_med)
			switch(src.prefs.job_engsec_med)
				if(CAPTAIN)
					work_chosen = "Baron"
				if(GATEKEEPER)
					work_chosen = "Charybdis"
				if(HAND)
					work_chosen = "Hand"
				if(HEIR)
					work_chosen = "Heir"
				if(HOS)
					work_chosen = "Kraken"
				if(WARDEN)
					work_chosen = "Warden"
				if(CHAPLAIN)
					work_chosen = "Vicar"
				if(DETECTIVE)
					work_chosen = "Detective"
				if(OFFICER)
					work_chosen = "Triton"
				if(CHIEF)
					work_chosen = "Engineer"
				if(ENGINEER)
					work_chosen = "Wright"
				if(ATMOSTECH)
					work_chosen = "Atmospheric Technician"
				if(AI)
					work_chosen = "AI"
				if(CYBORG)
					work_chosen = "Cyborg"
				if(SUCCESSOR)
					work_chosen = "Successor"
				if(SHERIFF)
					work_chosen = "Sheriff"
				if(SQUIRE)
					work_chosen = "Squire"
				if(HEIR)
					work_chosen = "Heir"
				if(BARONESS)
					work_chosen = "Baroness"
				if(MAID)
					work_chosen = "Maid"
				if(NUN)
					work_chosen = "Nun"
				if(MEISTERDISC)
					work_chosen = "Treasurer"
				if(PRACTICUS)
					work_chosen = "Sniffer"
				if(BGUARD)
					work_chosen = "Court Bodyguard"
				if(INQUISITOR)
					work_chosen = "Praetor"
				if(CONSYTE)
					work_chosen = "Consyte"
		else
			if(src.prefs.job_civilian_low)
				switch(src.prefs.job_civilian_low)
					if(HOP)
						work_chosen = "Meister"
					if(BARTENDER)
						work_chosen = "Bartender"
					if(BOTANIST)
						work_chosen = "Soiler"
					if(JANITOR)
						work_chosen = "Misero"
					if(QUARTERMASTER)
						work_chosen = "Merchant"
					if(CARGOTECH)
						work_chosen = "Docker"
					if(ENGINEER)
						work_chosen = "Wright"
					if(LAWYER)
						work_chosen = "Magistrate"
					if(CLOWN)
						work_chosen = "Jester"
					if(HOOKER)
						work_chosen = "Amuser"
					if(SMUGGLER)
						work_chosen = "Pusher"
					if(HOBO)
						work_chosen = "Bum"
					if(APPRENTICE)
						work_chosen = "Apprentice"
					if(SERVANT)
						work_chosen = "Servant"
					if(MIGRANT)
						work_chosen = "Migrant"
					if(MORTUS)
						work_chosen = "Mortus"
					if(SITZFRAU)
						work_chosen = "Sitzfrau"
					if(BUTLER)
						work_chosen = "Butler"
					if(SNIFFER)
						work_chosen = "Bum"
					if(CONSYTE)
						work_chosen = "Consyte"
					if(SCUFF)
						work_chosen = "Scuff"
					if(FACKID)
						work_chosen = "Minor Worker"
					if(HAG)
						work_chosen = "Fortune Teller"
					if(GANGER)
						work_chosen = "Ganger"
					if(CHEF)
						work_chosen = "Boozehound"
			else if(src.prefs.job_medsci_low)
				switch(src.prefs.job_medsci_low)
					if(RD)
						work_chosen = "Research Director"
					if(SCIENTIST)
						work_chosen = "Scientist"
					if(CHEMSIS)
						work_chosen = "Chemsister"
					if(METALSMITH)
						work_chosen = "Blacksmith"
					if(ARMORSMITH)
						work_chosen = "Blacksmith’s Assistant"
					if(CMO)
						work_chosen = "Esculap"
					if(DOCTOR)
						work_chosen = "Serpent"
					if(GENETICIST)
						work_chosen = "Counselor"
					if(URCHIN)
						work_chosen = "Urchin"
					if(MERC)
						work_chosen = "Mercenary"
					if(CONSYTE)
						work_chosen = "Consyte"
					if(INNKEEPERWIFE)
						work_chosen = "Madam"
					if(GUEST)
						work_chosen = "Guest"
					if(TRIBVET)
						work_chosen = "Tribunal Veteran"
			else if(src.prefs.job_engsec_low)
				switch(src.prefs.job_engsec_low)
					if(CAPTAIN)
						work_chosen = "Baron"
					if(GATEKEEPER)
						work_chosen = "Charybdis"
					if(HAND)
						work_chosen = "Hand"
					if(HEIR)
						work_chosen = "Heir"
					if(HOS)
						work_chosen = "Kraken"
					if(WARDEN)
						work_chosen = "Warden"
					if(CHAPLAIN)
						work_chosen = "Vicar"
					if(DETECTIVE)
						work_chosen = "Detective"
					if(OFFICER)
						work_chosen = "Triton"
					if(CHIEF)
						work_chosen = "Engineer"
					if(ENGINEER)
						work_chosen = "Wright"
					if(ATMOSTECH)
						work_chosen = "Atmospheric Technician"
					if(AI)
						work_chosen = "AI"
					if(CYBORG)
						work_chosen = "Cyborg"
					if(SUCCESSOR)
						work_chosen = "Successor"
					if(SHERIFF)
						work_chosen = "Sheriff"
					if(SQUIRE)
						work_chosen = "Squire"
					if(HEIR)
						work_chosen = "Heir"
					if(BARONESS)
						work_chosen = "Baroness"
					if(MAID)
						work_chosen = "Maid"
					if(NUN)
						work_chosen = "Nun"
					if(MEISTERDISC)
						work_chosen = "Treasurer"
					if(PRACTICUS)
						work_chosen = "Sniffer"
					if(BGUARD)
						work_chosen = "Court Bodyguard"
					if(INQUISITOR)
						work_chosen = "Praetor"
					if(CONSYTE)
						work_chosen = "Consyte"
		//work_chosen = "Unknown"

/client/New()
	..()
	winset(src, "name", "text=''") // when server reboots and stuff like that
	if(mob)
		winset(src, "name", "text='[mob.real_name]'")

/client/proc/notInvited()
	src << link("https://wiki.nearweb.org/images/6/69/Not_invited.jpg")
	src << 'sound/not_invited.ogg'
	del(src)
