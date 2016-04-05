open Sexplib.Conv
open Core.Std

(** NetKAT Syntax *)

(** {1 Basics} *)
open Frenetic_Packet

(* thrown whenever local policy is expected, but global policy
  (i.e. policy containing links) is encountered *)
exception Non_local

type switchId = Frenetic_OpenFlow.switchId [@@deriving sexp, yojson]
type portId = Frenetic_OpenFlow.portId [@@deriving sexp, yojson]
type payload = Frenetic_OpenFlow.payload [@@deriving sexp]
type vswitchId = int64 [@encoding `string] [@@deriving sexp, yojson]
type vportId = int64 [@encoding `string] [@@deriving sexp, yojson]
type vfabricId = int64 [@encoding `string] [@@deriving sexp, yojson]

(** {2 Headers} *)

type location =
  | Physical of int32
  | FastFail of int32 list
  | Pipe of string
  | Query of string
  [@@deriving sexp, yojson]

type header_val =
  | Switch of switchId
  | Location of location
  | EthSrc of dlAddr
  | EthDst of dlAddr
  | Vlan of int16
  | VlanPcp of dlVlanPcp
  | EthType of dlTyp
  | IPProto of nwProto
  | IP4Src of nwAddr * int32
  | IP4Dst of nwAddr * int32
  | TCPSrcPort of tpPort
  | TCPDstPort of tpPort
  | VSwitch of vswitchId
  | VPort of vportId
  | VFabric of vfabricId
  [@@deriving sexp, yojson]


(** {3 Policies} *)

type pred =
  | True
  | False
  | Test of header_val
  | And of pred * pred
  | Or of pred * pred
  | Neg of pred
  [@@deriving sexp, yojson]

type policy =
  | Filter of pred
  | Mod of header_val
  | Union of policy * policy
  | Seq of policy * policy
  | Star of policy
  | Link of switchId * portId * switchId * portId
  | VLink of vswitchId * vportId * vswitchId * vportId
  [@@deriving sexp, yojson]

let id = Filter True
let drop = Filter False


(** {4 Applications} *)

type action = Frenetic_OpenFlow.action

type switch_port = switchId * portId [@@deriving sexp]
type host = Frenetic_Packet.dlAddr * Frenetic_Packet.nwAddr [@@deriving sexp]

type bufferId = Int32.t [@@deriving sexp] (* XXX(seliopou): different than Frenetic_OpenFlow *)

type event =
  | PacketIn of string * switchId * portId * payload * int
  | Query of string * int64 * int64
  | SwitchUp of switchId * portId list
  | SwitchDown of switchId
  | PortUp of switch_port
  | PortDown of switch_port
  | LinkUp of switch_port * switch_port
  | LinkDown of switch_port * switch_port
  | HostUp of switch_port * host
  | HostDown of switch_port * host
  [@@deriving sexp]

(** {5 Applications} **)
let string_of_fastfail = Frenetic_OpenFlow.format_list ~to_string:Int32.to_string
