# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

async def await_it(arg):
    await arg

async def dont_await_it(arg):
    pass


class C:
    class_property = "testmod.C.class_property"
    def __init__(self):
        self.property = "testmod.C.instance_property"
