open Ox
open OpenFlow0x01 (* TODO(arjun): fix *)
open OpenFlow0x01_Core
open OxPlatform

(* Extend OxTutorial4 to also implement its packet_in handler efficiently
   in the flow table. This is not complete! But, an intermediate point. *)
module MyApplication : OXMODULE = struct

  let match_icmp = 
    { dlSrc = None; dlDst = None; dlTyp = Some 0x800; dlVlan = None;
      dlVlanPcp = None; nwSrc = None; nwDst = None; nwProto = Some 1;
      nwTos = None; tpSrc = None; tpDst = None; inPort = None }

  let match_http_requests = 
    { dlSrc = None; dlDst = None; dlTyp = Some 0x800; dlVlan = None;
      dlVlanPcp = None; nwSrc = None; nwDst = None; nwProto = Some 6;
      nwTos = None; tpSrc = None; tpDst = Some 80; inPort = None }

  let match_http_responses = 
    { dlSrc = None; dlDst = None; dlTyp = Some 0x800; dlVlan = None;
      dlVlanPcp = None; nwSrc = None; nwDst = None; nwProto = Some 6;
      nwTos = None; tpSrc = Some 80; tpDst = None; inPort = None }

  (* TODO(arjun): I think we provide this function here, and explain what
     it does. *)
  let rec periodic_stats_request sw interval pat =
    let callback () =
      Printf.printf "Sending stats request to %Ld\n%!" sw; 
      send_stats_request sw 0l
        (StatsRequest.AggregateRequest (pat, 0xff, None));
      periodic_stats_request sw interval pat in
    timeout interval callback

  (* FILL: configure the flow table to efficiently implement the packet
     processing function you've written in packet_in. Also need to send
     stat-requests. *)
  let switch_connected (sw : switchId) : unit =
    Printf.printf "Switch %Ld connected.\n%!" sw;
    periodic_stats_request sw 5.0 match_http_requests;
    periodic_stats_request sw 5.0 match_http_responses;   
    send_flow_mod sw 0l
      (add_flow 200 match_icmp []);
    send_flow_mod sw 1l
      (add_flow 199 match_http_requests 
         [Output AllPorts]);
    send_flow_mod sw 1l
      (add_flow 198 match_http_responses 
         [Output AllPorts]);
    send_flow_mod sw 1l
      (add_flow 197 match_all [Output AllPorts])
      
  let switch_disconnected (sw : switchId) : unit =
    Printf.printf "Switch %Ld disconnected.\n%!" sw

  let num_http_packets = ref 0

  let is_http_packet (pk : Packet.packet) : bool = 
    Packet.dlTyp pk = 0x800 &&
    Packet.nwProto pk = 6 &&
    (Packet.tpSrc pk = 80 || Packet.tpDst pk = 80)

  (* [FILL IN HERE] Use the packet_in function you write in OxTutorial4. *)
  let packet_in (sw : switchId) (xid : xid) (pktIn : packetIn) : unit =
    if is_http_packet (parse_payload pktIn.input_payload) then
      begin
        num_http_packets := !num_http_packets + 1;
        Printf.printf "Seen %d HTTP packets.\n%!" !num_http_packets
      end;
    let payload = pktIn.input_payload in
    let pk = parse_payload payload in
    if Packet.dlTyp pk = 0x800 && Packet.nwProto pk = 1 then
      send_packet_out sw 0l
        { output_payload = payload;
          port_id = None;
          apply_actions = []
        }
    else 
      send_packet_out sw 0l
        { output_payload = payload;
          port_id = None;
          apply_actions = [Output AllPorts]
        }

  let barrier_reply (sw : switchId) (xid : xid) : unit =
    ()

  let stats_reply (sw : switchId) (xid : xid) (stats : StatsReply.t) : unit =
    Printf.printf "Received a StatsReply from switch %Ld:\n%s\n%!"
      sw (StatsReply.to_string stats)

  let port_status (sw : switchId) (xid : xid) (port : PortStatus.t) : unit =
    ()

end

module Controller = Make (MyApplication)
