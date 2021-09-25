#include maps/mp/zm_highrise_sq;
#include maps/mp/zombies/_zm_sidequests;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/zm_highrise_sq_pts;
#include maps/mp/zm_highrise_sq_atd;


init(){
	replaceFunc(maps/mp/zm_highrise_sq_atd::sq_atd_drg_puzzle, ::custom_sq_atd_drg_puzzle);
	replaceFunc(maps/mp/zm_highrise_sq_atd::drg_puzzle_trig_think, ::custom_drg_puzzle_trig_think);
	replaceFunc(maps/mp/zm_highrise_sq_atd::sq_atd_elevators, ::custom_sq_atd_elevators);
	replaceFunc(maps/mp/zm_highrise_sq_pts::wait_for_all_springpads_placed, ::custom_wait_for_all_springpads_placed);
}

//Make it report springpad counts, might or might not require further improvement
custom_springpad_count_watcher( is_generator ){
	level endon( "sq_pts_springad_count4" );
	while ( 1 )	{
		n_count = 0;
		n_count++;
		level notify( "sq_pts_springad_count" + n_count );
		wait 1;
	}
	level iPrintLnBold("sq_pts_springpad_count4 notified");
}

//Hopefully working Springpad count skip 
custom_wait_for_all_springpads_placed( str_type, str_flag ){
	//str_type is basically useless, but has to be kept as other functions will call with an str_type
	while ( !flag( str_flag ) )	{
		flag_set( str_flag );
		iPrintLnBold("PTS count skip");
		wait 1;
	}
}

//Dragon Puzzle step

custom_sq_atd_drg_puzzle(){
//No reset, requires as many dragons as players in the match
	level.sq_atd_cur_drg = (4 - getPlayers().size);
	a_puzzle_trigs = getentarray( "trig_atd_drg_puzzle", "targetname" );
	a_puzzle_trigs = array_randomize( a_puzzle_trigs );
	i = (0);
	while ( i < a_puzzle_trigs.size )	{
		a_puzzle_trigs[ i ] thread drg_puzzle_trig_think( i );
		i++;
	}
	while ( level.sq_atd_cur_drg < 4 )	{
		wait 1;
	}
	flag_set( "sq_atd_drg_puzzle_complete" );
	level thread vo_maxis_atd_order_complete();

}

custom_drg_puzzle_trig_think( n_order_id ){
	self.drg_active = 0;
	m_unlit = getent( self.target, "targetname" );
	m_lit = m_unlit.lit_icon;
	v_top = m_unlit.origin;
	v_hidden = m_lit.origin;
	while ( !flag( "sq_atd_drg_puzzle_complete" ) )	{
		while ( self.drg_active )		{
			level waittill( "sq_atd_drg_puzzle_complete" );
		}
		self waittill( "trigger", e_who );
		if ( level.sq_atd_cur_drg == n_order_id )		{
			m_lit.origin = v_top;
			m_unlit.origin = v_hidden;
			m_lit playsound( "zmb_sq_symbol_light" );
			self.drg_active = 1;
			level thread vo_richtofen_atd_order( level.sq_atd_cur_drg );
			level.sq_atd_cur_drg++;
			self thread drg_puzzle_trig_watch_fade( m_lit, m_unlit, v_top, v_hidden );
		}
		while ( e_who istouching( self ) )		{
			wait 0.5;
		}
	}
}

//Elevator Stand step

custom_sq_atd_elevators(){
	a_elevators = array( "elevator_bldg1b_trigger", "elevator_bldg1d_trigger", "elevator_bldg3b_trigger", "elevator_bldg3c_trigger" );
	a_elevator_flags = array( "sq_atd_elevator0", "sq_atd_elevator1", "sq_atd_elevator2", "sq_atd_elevator3" );
	i = 0;
	while ( i < a_elevators.size )	{
		trig_elevator = getent( a_elevators[ i ], "targetname" );
		trig_elevator thread sq_atd_watch_elevator( a_elevator_flags[ i ] );
		i++;
	}
	//While no elevator, wait until any and break
	while ( !flag( "sq_atd_elevator0" ) && !flag( "sq_atd_elevator1" ) && !flag( "sq_atd_elevator2" ) && !flag( "sq_atd_elevator3" ) ){
		flag_wait_any_array( a_elevator_flags );
		wait 0.5;
	}	
	a_dragon_icons = getentarray( "elevator_dragon_icon", "targetname" );
	_a105 = a_dragon_icons;
	_k105 = getFirstArrayKey( _a105 );
	while ( isDefined( _k105 ) )	{
		m_icon = _a105[ _k105 ];
		v_off_pos = m_icon.m_lit_icon.origin;
		m_icon.m_lit_icon unlink();
		m_icon unlink();
		m_icon.m_lit_icon.origin = m_icon.origin;
		m_icon.origin = v_off_pos;
		m_icon.m_lit_icon linkto( m_icon.m_elevator );
		m_icon linkto( m_icon.m_elevator );
		m_icon playsound( "zmb_sq_symbol_light" );
		_k105 = getNextArrayKey( _a105, _k105 );
	}
	flag_set( "sq_atd_elevator_activated" );
	vo_richtofen_atd_elevators();
	level thread vo_maxis_atd_elevators();
}
