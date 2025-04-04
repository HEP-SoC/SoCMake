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

#ifndef CONSUMER_H_
#define CONSUMER_H_

#include <systemc>
#include <uvm>

#include "packet.h"

template <typename T = packet>
class consumer : public uvm::uvm_component
{
 public:
  uvm::uvm_blocking_put_imp<T,consumer<T> > in;
  uvm::uvm_get_port<T> out;

  consumer( uvm::uvm_component_name name )
  : uvm::uvm_component(name),
    in("in", this),
    out("out"),
    count(0)
  {}

  UVM_COMPONENT_UTILS(consumer<T>);

  virtual void run_phase(uvm::uvm_phase& phase)
  {
    T p;
    while(out.size())
    {
      out->get(p);
      put(p);
    }
  }

  void put(const T& p)
  {
    m.lock(); //lock.get();

    count++;

    accept_tr(p);
    sc_core::wait(10, sc_core::SC_US);

    begin_tr(p);

    sc_core::wait(30, sc_core::SC_US);
    end_tr(p);

    std::ostringstream str;
    str << "Received "
        << p
        << " local_count="
        << count;

    UVM_INFO("consumer", str.str(), uvm::UVM_MEDIUM);

    if( uvm::uvm_report_enabled( uvm::UVM_HIGH, uvm::UVM_INFO, ""))
      p.print();

    m.unlock(); //lock.put();
  }

 private:
  int count;
  sc_core::sc_mutex m; // semaphore lock
};

#endif /* CONSUMER_H_ */
