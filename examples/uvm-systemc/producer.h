//----------------------------------------------------------------------
//   Copyright 2014 NXP B.V.
//   Copyright 2007-2010 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc.
//   Copyright 2010-2011 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

#ifndef PRODUCER_H_
#define PRODUCER_H_

#include <systemc>
#include <uvm>

#include "packet.h"

template <typename T = packet>
class producer : public uvm::uvm_component
{
 public:
  uvm::uvm_blocking_put_port<T> out;

  producer( uvm::uvm_component_name name ) : uvm::uvm_component(name), out("out"), num_packets(0), count(0)
  {
    uvm::uvm_config_db<int>::get(this, "", "num_packets", num_packets);
  }

/* TODO implement all transaction functions
  `uvm_component_utils_begin(producer #(T))
    `uvm_field_object(proto, UVM_ALL_ON + UVM_REFERENCE)
    `uvm_field_int(num_packets, UVM_ALL_ON + UVM_DEC)
    `uvm_field_int(count, UVM_ALL_ON + UVM_DEC + UVM_READONLY)
  `uvm_component_utils_end
*/

  virtual void run_phase( uvm::uvm_phase& phase )
  {
    T p;
    std::stringstream num;

    UVM_INFO(get_name(), "Starting.", uvm::UVM_MEDIUM);

    for (count = 0; count < num_packets; count++)
    {
      num.str(""); // clear string
      num << count;

      p.set_name(get_name() + "-" + num.str());

      // TODO
      //p.set_initiator(this);
      //if ((uvm::uvm_verbosity)recording_detail != uvm::UVM_NONE)
      //  p.enable_recording("packet_stream");
      //  p.randomize();
	
      // fill address field with dummy value
      p.addr = 0x100 + count;

      UVM_INFO(get_name(), "Sending " + p.get_name(), uvm::UVM_MEDIUM);

      if( uvm_report_enabled( uvm::UVM_HIGH, uvm::UVM_INFO, ""))
        p.print();

      out->put(p);
      sc_core::wait(10.0, sc_core::SC_US); // 10us;
    }

    UVM_INFO(get_name(), "Exiting.", uvm::UVM_MEDIUM);
  }

 protected:
  T proto;
  int num_packets;
  int count;
};

#endif /* PRODUCER_H_ */
