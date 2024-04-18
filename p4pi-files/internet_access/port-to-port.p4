#include <core.p4>
#include <v1model.p4>


header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata {}

struct headers {
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }

}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {}
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action _nop() {}
    
    action forward(bit<9> port) {
        standard_metadata.egress_spec = port;
    }

    action drop() {
        mark_to_drop( standard_metadata );
        exit;
    }

    action forward_one() {
	    forward(1);
    }

    table dmac {
        actions = {
            forward;
    	    forward_one;
            drop;
        }

        key = {
            hdr.ethernet.dstAddr: exact;
        }

        default_action = forward_one();
        size = 512;
    }

    apply {
        if (standard_metadata.ingress_port == 1) {
            forward(0);
        } else {
            forward(1);
        }

        dmac.apply();
    }

}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
