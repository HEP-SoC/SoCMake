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

#ifndef PACKET_H_
#define PACKET_H_

#include <uvm>

class packet : public uvm::uvm_transaction
{
 public:
  int addr;

  UVM_OBJECT_UTILS(packet);

  // TODO constraints
  //constraint c { addr >= 0 && addr < 'h100; }

  packet( std::string name = "packet" )
  : uvm_transaction(name)
  {}

  virtual void do_print(const uvm::uvm_printer& printer) const
  {
    printer.print_field_int("addr", addr);
  }

};

#endif /* PACKET_H_ */
