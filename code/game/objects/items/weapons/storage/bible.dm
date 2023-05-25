/obj/item/storage/bible
	name = "bible"
	desc = "Apply to head repeatedly."
	icon_state ="bible"
	item_state = "bible"
	throw_speed = 1
	throw_range = 5
	w_class = 3.0
	flags = FPRINT | TABLEPASS
	var/mob/affecting = null
	var/deity_name = "Christ"

/obj/item/storage/bible/booze
	name = "bible"
	desc = "To be applied to the head repeatedly."
	icon_state ="bible"

/obj/item/storage/bible/booze/New()
	..()
	new /obj/item/reagent_containers/glass/bottle/beer(src)
	new /obj/item/reagent_containers/glass/bottle/beer(src)
	new /obj/item/spacecash(src)
	new /obj/item/spacecash(src)
	new /obj/item/spacecash(src)

/obj/item/storage/bible/attack_self(mob/living/carbon/human/user as mob)
	if((user.job != "Vicar") && (user.job != "Praetor") && (user.job != "Priest"))
		return
		var/list/frasestosay = list("Finally, be strong in the Lord and in his mighty power. Put on the whole armor of God, so that you can stand firm against the wiles of the Devil, for our fight is not against human beings, but against the powers and authorities, against the rulers of this dark world, against the spiritual forces of evil in the heavenly places. Therefore, put on the whole armor of God, so that you may be able to withstand on the evil day and stand firm, after you have done everything.",\
"Blessed be the Lord, my Rock, who trains my hands for war and my fingers for battle. He is my faithful ally, my fortress, my tower of protection and my deliverer; he is my shield, he in whom I take refuge. He subdues the peoples under me.",
"For although we live like men, we do not fight according to human standards. The weapons with which we fight are not human weapons, but are mighty in God to pull down strongholds. We tear down arguments and every pretense that sets itself up against the knowledge of God and We take every thought captive to make it obedient to Christ.",
"Fight the good fight of faith. Take hold of the eternal life to which you were called and which you made the good confession in the presence of many witnesses.","Bear with me in my sufferings, as a good soldier of Christ Jesus. No soldier gets involved in the affairs of civilian life, since he wants to please the one who enlisted him.",
"I have fought the good fight, I have finished the race, I have kept the faith. Now there is reserved for me the crown of righteousness, which the Lord, the righteous Judge, will give me on that day; and not to me only, but also to all who love his coming.",
"The Lord is my strength and my song; he is my salvation! He is my God, and I will praise him; he is the God of my father, and I will exalt him! The Lord is a warrior, his name is God."
			)
		user.say(pick(frasestosay))


/obj/item/storage/bible/attack(mob/living/M as mob, mob/living/user as mob)
	..()
	if(user.mind && (user.mind.assigned_role == "Vicar" || user.mind.assigned_role == "Priest"))
		user.show_message(text("\red <B>[user] blesses [M]!</B>"), 1)
		playsound(src.loc, 'sound/weapons/hallelujah.ogg', 40, 0, -1)
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(H.religion == "Gray Church")
				H.add_event("bless", /datum/happiness_event/blessed)
			if(H.religion != "Gray Church")
				H.add_event("bless", /datum/happiness_event/badblessed)

//BS12 EDIT
/* // All cult functionality moved to Null Rod
/obj/item/storage/bible/proc/bless(mob/living/carbon/M as mob)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/heal_amt = 10
		for(var/datum/organ/external/affecting in H.organs)
			if(affecting.heal_damage(heal_amt, heal_amt))
				H.UpdateDamageIcon()
	return

/obj/item/storage/bible/attack(mob/living/M as mob, mob/living/user as mob)

	var/chaplain = 0
	if(user.mind && (user.mind.assigned_role == "Chaplain"))
		chaplain = 1


	M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been attacked with [src.name] by [user.name] ([user.ckey])</font>")
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>Used the [src.name] to attack [M.name] ([M.ckey])</font>")

	log_attack("<font color='red'>[user.name] ([user.ckey]) attacked [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>")

	if (!(istype(user, /mob/living/carbon/human) || ticker) && ticker.mode.name != "monkey")
		user << "\red You don't have the dexterity to do this!"
		return
	if(!chaplain)
		user << "\red The book sizzles in your hands."
		user.take_organ_damage(0,10)
		return

	if ((CLUMSY in user.mutations) && prob(50))
		user << "\red The [src] slips out of your hand and hits your head."
		user.take_organ_damage(10)
		user.Paralyse(20)
		return

//	if(..() == BLOCKED)
//		return

	if (M.stat !=2)
		if(M.mind && (M.mind.assigned_role == "Chaplain"))
			user << "\red You can't heal yourself!"
			return
		/*if((M.mind in ticker.mode.cult) && (prob(20)))
			M << "\red The power of [src.deity_name] clears your mind of heresy!"
			user << "\red You see how [M]'s eyes become clear, the cult no longer holds control over him!"
			ticker.mode.remove_cultist(M.mind)*/
		if ((istype(M, /mob/living/carbon/human) && prob(60)))
			bless(M)
			for(var/mob/O in viewers(M, null))
				O.show_message(text("\red <B>[] heals [] with the power of [src.deity_name]!</B>", user, M), 1)
			M << "\red May the power of [src.deity_name] compel you to be healed!"
			playsound(src.loc, "punch", 25, 1, -1)
		else
			if(ishuman(M) && !istype(M:head, /obj/item/clothing/head/helmet))
				M.adjustBrainLoss(10)
				M << "\red You feel dumber."
			for(var/mob/O in viewers(M, null))
				O.show_message(text("\red <B>[] beats [] over the head with []!</B>", user, M, src), 1)
			playsound(src.loc, "punch", 25, 1, -1)
	else if(M.stat == 2)
		for(var/mob/O in viewers(M, null))
			O.show_message(text("\red <B>[] smacks []'s lifeless corpse with [].</B>", user, M, src), 1)
		playsound(src.loc, "punch", 25, 1, -1)
	return
*/
/obj/item/storage/bible/afterattack(atom/A, mob/user as mob, proximity)
	if(!proximity) return
/*	if (istype(A, /turf/simulated/floor))
		user << "\blue You hit the floor with the bible."
		if(user.mind && (user.mind.assigned_role == "Chaplain"))
			call(/obj/effect/rune/proc/revealrunes)(src)*/
	if(user.mind && (user.mind.assigned_role == "Vicar" || user.mind.assigned_role == "Priest"))
		if(A.reagents && A.reagents.has_reagent("water")) //blesses all the water in the holder
			user << "\blue You bless [A]."
			var/water2holy = A.reagents.get_reagent_amount("water")
			A.reagents.del_reagent("water")
			A.reagents.add_reagent("holywater",water2holy)

/obj/item/storage/bible/attackby(obj/item/W as obj, mob/user as mob)
	playsound(src.loc, "rustle", 50, 1, -5)
	..()
