//----------------------------------------------------------------------
//   Copyright 2014 NXP B.V.
//   Copyright 2007-2010 Mentor Graphics Corporation
//   Copyright 2007-2010 Cadence Design Systems, Inc.
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

#ifndef TOP_H_
#define TOP_H_

#include <systemc>
#include <uvm>

#include "producer.h"
#include "consumer.h"
#include "packet.h"

class top : public uvm::uvm_component
{
 public:
  producer<packet> p1;
  producer<packet> p2;
  tlm::tlm_fifo<packet> f;  // there is no uvm_tlm_fifo in UVM-SystemC

  consumer<packet> c;

  UVM_COMPONENT_UTILS(top);

  top( uvm::uvm_component_name name )
  : uvm::uvm_component(name),
    p1("producer1"),
    p2("producer2"),
    f("fifo"),
    c("consumer")
  {
    p1.out.connect(c.in);
    p2.out.connect(f); // f.blocking_put_export
    c.out.connect(f);  // f.get_export
  }

  virtual void run_phase( uvm::uvm_phase& phase )
  {
     phase.raise_objection(this);
     sc_core::wait(1.0, sc_core::SC_MS); // 1ms
     phase.drop_objection(this);
  }
};

#endif /* TOP_H_ */
