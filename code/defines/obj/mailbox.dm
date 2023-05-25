/obj/item/storage/drawer
	name = "drawer"
	icon = 'icons/obj/surgery.dmi'
	icon_state = "drawer"
	anchored = 0
	heavy = 1
	density = 1
	force = 8.0
	w_class = 8.0
	max_w_class = 8

/obj/item/storage/drawer/utility
	icon_state = "utility"

/obj/item/storage/drawer/furniture
	icon_state = "furniture1"

/obj/item/storage/drawer/furniture/New()
	..()
	icon_state = "furniture[rand(1,6)]"

/obj/item/storage/drawer/New()
	..()
	spawn(1)
		for(var/obj/item/I in src.loc)
			if(I.density || I.anchored || I == src) continue
			I.loc = src

/obj/item/storage/drawer/attack_hand(mob/user as mob)
	orient2hud(user)          // dunno why it wasn't before
	if(user.s_active)
		user.s_active.close(user)
	show_to(user)
	playsound(src.loc, 'sound/effects/drawer_sound.ogg', 75, 0)
	user.visible_message("<span class='passivebold'>[user.name] opens the [src].</span>")

/obj/item/storage/mail_box/kick_act()
	return

/obj/item/storage/mail_box
	name = "mail box"
	desc = "a mail box utilised to send posting cards"
	icon = 'icons/lifeplat/facamaluca.dmi'
	icon_state = "mailbox0"
	density = 0
	anchored = 1
	force = 8.0
	w_class = 8.0
	max_w_class = 8
	plane = 21
	var/list/mail_sounds = list('sound/effects/mail1.ogg', 'sound/effects/mail2.ogg', 'sound/effects/mail3.ogg', 'sound/effects/mail4.ogg')

/obj/item/storage/mail_box/New()
	..()
	new/obj/item/pen(src)
	new/obj/item/paper(src)
	new/obj/item/paper(src)
	new/obj/item/paper(src)

/obj/item/storage/mail_box/RightClick(mob/living/carbon/human/user as mob)
	. = ..()

	for(var/obj/item/package/P in evermail_ref)
		if(P.ToPerson == user.real_name)
			alert("There's a package with my name.")
			switch(alert("Will you take the package?", "PACKAGE", "Yes", "No"))
				if("Yes")
					evermail_ref.contents.Remove(P)
					P.loc = user.loc
					P.loc = src.loc
					src.contents += P
					playsound(user.loc, 'sound/webbers/mail_old.ogg', 60, 1)
				if("No")
					return

	for(var/obj/item/letter/P in evermail_ref)
		if(P.ToPerson == user.real_name)
			alert("There's a mail with my name.")
			switch(alert("Will you take the package?", "PACKAGE", "Yes", "No"))
				if("Yes")
					evermail_ref.contents.Remove(P)
					P.loc = user.loc
					P.loc = src.loc
					src.contents += P
					playsound(user.loc, 'sound/webbers/mail_old.ogg', 60, 1)
				if("No")
					return

	if(istype(user.wear_id, /obj/item/card/id/churchkeeper) && Inquisitor_Points >= 0)
		var/list/EQUIPMENT = list()

		var/list/WHAT = list(list("Baton(3)", /obj/item/melee/classic_baton/tonfa),list("Noctis-5(6)", /obj/item/gun/energy/taser/leet/noctis), list("Handcuffs(1)", /obj/item/handcuffs), list("Sword(3)", /obj/item/claymore), list("Sword(3)", /obj/item/claymore), list("Silver Dagger(1)", /obj/item/kitchen/utensil/knife/dagger/silver), list("Silver Dagger(1)", /obj/item/kitchen/utensil/knife/dagger/silver), list("Club(2)", /obj/item/melee/classic_baton/club), list("Crossbow(1)", /obj/item/crossbow), list("Crossbow Bolts(1)", /obj/item/arrow), list("Energy Shield(3)", /obj/item/shield/generator), list("Silver Obols(2)", /obj/item/spacecash/silver/c15), list("Gas Mask(1)", /obj/item/clothing/mask/gas/church), list("Gas Grenade(1)", /obj/item/grenade/smokebomb/church), list("Flashbang(1)", /obj/item/grenade/flashbang), list("Satchel(2)", /obj/item/storage/backpack/minisatchelchurch), list("Telescopic Staff(2)", /obj/item/melee/telebaton), list("Fencer Gloves(1)", /obj/item/clothing/gloves/black/inquisitor), list("INKVD Cap(1)", /obj/item/clothing/head/inqcap), list("Black Bag(1)", /obj/item/clothing/head/blackbag), list("Noctis Recharger(1)", /obj/item/cell/crap/leet/noctis), list("Sonic Screwdriver(10)", /obj/item/sonic_screwdriver), list("Sunglasses(1)", /obj/item/clothing/glasses/sunglasses))

		for(var/list/L in WHAT)
			EQUIPMENT.Add(L[1])

		var/inquisidor_tipos = input(user, "choose your equipment") as null|anything in EQUIPMENT

		for(var/list/L in WHAT)
			if(L[1] == inquisidor_tipos)
				var/price = text2num(replacetext(splittext(inquisidor_tipos, "(")[2], ")", ""))
				if(Inquisitor_Points < price)
					return
				Inquisitor_Points -= price
				var/A = L[2]
				playsound(src.loc, pick(mail_sounds), 75, 1)
				return new A(src)

/obj/item/storage/mail_box/attack_hand(mob/user as mob)
	orient2hud(user)          // dunno why it wasn't before
	if(user.s_active)
		user.s_active.close(user)
	show_to(user)
	playsound(src.loc, 'sound/effects/drawer_sound.ogg', 75, 0)
	user.visible_message("<span class='passivebold'>[user.name] opens the [src].</span>")

/obj/item/storage/mail_box/attackby(obj/item/I as obj, mob/living/carbon/human/user as mob)
	if(istype(I, /obj/item/package))
		var/obj/item/package/P = I
		var/fromPerson = input(user, "From who?", "SENDER") as text
		var/toPerson = input(user, "To who?", "DESTINATARY") as text
		P.FromPerson = fromPerson
		P.ToPerson = toPerson
		P.desc = "From [fromPerson] to [toPerson]"
		user.drop_from_inventory(P)
		evermail_ref.receive(P)
		return

	if(istype(I, /obj/item/avowal))
		var/obj/item/avowal/A = I
		if(A.signedby)
			for(var/mob/living/carbon/human/H in mob_list)
				if(H.job == "Praetor")
					Inquisitor_Points += 5
					H.mind.avowals_of_guilt_sent += 1
					A.signedby = null
					qdel(A)
					to_chat(H, "5 Points recieved for the avowal.")
					if( Inquisitor_Type == "Month's Inquisitor")
						if(H.mind.avowals_of_guilt_sent == 6)
							H?.client?.ChromieWinorLoose(3)

	if(istype(I, /obj/item/organ/head))
		var/obj/item/organ/head/A = I
		user.qualarea()
		if(user.lastarea && istype(user.lastarea, /area/dunwell/station/church))
			if(A.marked)
				if(user.religion == "Gray Church")
					playsound(src.loc, pick(mail_sounds), 75, 1)
					qdel(A)
					user?.client?.ChromieWinorLoose(3)
				else if(user.religion == "Thanati")
					to_chat(user, "I SHOULDN'T HAVE DONE THAT!")
					user.on_fire = TRUE
					user.update_fire()
				else
					return

	if(istype(I, /obj/item/paper))
		var/obj/item/paper/A = I
		if(ticker.mode.config_tag == "siege" && user.job == "Count")
			var/datum/game_mode/siege/S = ticker.mode
			if(S.siegewar)
				return
			if(length(A.info) <= 150)
				to_chat(user, "<span class='combat'>Message is too short!</span>")
				return
			for(var/mob/living/carbon/human/SG in S.siegerslist)
				to_chat(SG, "<br>")
				to_chat(SG, "<span class='excomm'>¤ [user.job] [user.real_name] declares war on Enoch's Gate. ¤</span>")
				SG << sound('sound/AI/siege_declared.ogg')
				to_chat(SG, "<br>")
			for(var/obj/effect/trip/siege/TR in trip_markers)
				TR.pulling_mob = TRUE
			playsound(src.loc, pick(mail_sounds), 75, 1)
			user.drop_item()
			spawn(100)
				evermail_ref.receive(A, 1)
				S.war_paper = A
				S.siegewar = TRUE
		else if(A.thanatos())
			for(var/mob/living/carbon/human/H in mob_list)
				if(H.job == "Praetor")
					Inquisitor_Points += 5
					H.mind.avowals_of_guilt_sent += 1
					playsound(src.loc, pick(mail_sounds), 75, 1)
					qdel(A)
					to_chat(H, "5 Points recieved for the confession paper.")
		else if(A.info)
			playsound(src.loc, pick(mail_sounds), 75, 1)
			user.drop_item()
			var/fromPerson = input(user, "From who?", "SENDER") as text
			var/toPerson = input(user, "To who?", "DESTINATARY") as text
			var/obj/item/letter/carta = new(A.loc)
			carta.FromPerson = fromPerson
			carta.ToPerson = toPerson
			carta.desc = "From [fromPerson] to [toPerson]"
			A.loc = carta
			evermail_ref.receive(carta)
	else
		..()

var/global/obj/item/storage/evermail/evermail_ref = null

/obj/item/storage/evermail
	name = "evermail"
	icon = 'icons/lifeplat/facamaluca.dmi'
	icon_state = "evermail0"
	anchored = 1
	heavy = 1
	density = 1
	force = 8.0
	w_class = 8.0
	max_w_class = 8

/obj/item/storage/evermail/New()
	..()
	spawn(1)
		for(var/obj/item/I in src.loc)
			if(I.density || I.anchored || I == src) continue
			I.loc = src
	evermail_ref = src

/obj/item/storage/evermail/attack_hand(mob/user as mob)
	orient2hud(user)          // dunno why it wasn't before
	if(user.s_active)
		user.s_active.close(user)
	show_to(user)
	playsound(src.loc, 'sound/effects/drawer_sound.ogg', 75, 1)
	user.visible_message("<span class='passivebold'>[user.name] opens the [src].</span>")

/obj/item/storage/evermail/proc/receive(var/obj/item/P, var/isImportantMessage=0)
	flick("evermail1", src)
	P.loc = src
	if(isImportantMessage)
		to_chat(world, "<br>")
		to_chat(world, "<span class='ravenheartfortress'>Enoch's Gate Hold</span>")
		to_chat(world, "<span class='excomm'>Urgent message to the Lord Baron!</span>")
		world << sound('sound/webbers/newstate_notice.ogg')
		to_chat(world, "<br>")
	else
		playsound(src.loc, 'sound/webbers/interferencia.ogg', 100, 1)
	if(istype(P, /obj/item/package))
		var/obj/item/package/pacote = P
		for(var/mob/living/carbon/human/H in mob_list)
			if(H.client && H.real_name == pacote.ToPerson)
				var/mayRecieve = 0
				var/obj/item/device/radio/headset/bracelet/B = null
				if(istype(H.wrist_r, /obj/item/device/radio/headset/bracelet))
					mayRecieve = 1
					B = H.wrist_r
				if(istype(H.wrist_l, /obj/item/device/radio/headset/bracelet))
					mayRecieve = 1
					B = H.wrist_l
				flick("braceletwarn", B)
				if(mayRecieve)
					to_chat(H, "<span class='passive'>[icon2html(B, H)] Your bracelet blinks. You have received a mail.")
					H << 'sound/webbers/mail_generic.ogg'
	if(istype(P, /obj/item/letter))
		var/obj/item/letter/pacote = P
		for(var/mob/living/carbon/human/H in mob_list)
			if(H.client && H.real_name == pacote.ToPerson)
				var/mayRecieve = 0
				var/obj/item/device/radio/headset/bracelet/B = null
				if(istype(H.wrist_r, /obj/item/device/radio/headset/bracelet))
					mayRecieve = 1
					B = H.wrist_r
				if(istype(H.wrist_l, /obj/item/device/radio/headset/bracelet))
					mayRecieve = 1
					B = H.wrist_l
				flick("braceletwarn", B)
				if(mayRecieve)
					to_chat(H, "<span class='passive'>[icon2html(B, H)] Your bracelet blinks. You have received a mail.")
					H << 'sound/webbers/mail_generic.ogg'

/obj/item/package
	name = "package"
	gender = PLURAL
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "package"
	flammable = 1
	throwforce = 0
	w_class = 1.0
	throw_range = 1
	throw_speed = 1
	layer = 4
	pressure_resistance = 1
	var/FromPerson
	var/ToPerson

/obj/item/package/attack_self(mob/user)
	playsound(src.loc, 'sound/webbers/unpackage.ogg', 75, 1)
	if(do_after(user, 20))
		for(var/obj/item/I in src)
			I.loc = get_turf(user)
		qdel(src)

/obj/item/letter
	name = "letter"
	gender = PLURAL
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "letter"
	flammable = 1
	throwforce = 0
	w_class = 1.0
	throw_range = 1
	throw_speed = 1
	layer = 4
	pressure_resistance = 1
	var/FromPerson
	var/ToPerson

/obj/item/letter/attack_self(mob/user)
	playsound(src.loc, 'sound/webbers/unpackage.ogg', 75, 1)
	if(do_after(user, 20))
		for(var/obj/item/I in src)
			I.loc = get_turf(user)
		qdel(src)
