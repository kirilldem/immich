import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { findNonDeletedExtension } from '../prisma/extensions/findNonDeleted';
import { metricsExtension } from '../prisma/extensions/metrics';

@Injectable()
export class PrismaRepository extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    super();
    return this.$extends(metricsExtension).$extends(findNonDeletedExtension) as this;
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
