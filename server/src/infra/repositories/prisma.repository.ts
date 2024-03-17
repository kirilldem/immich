import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { metricsExtension } from '../prisma/extensions/metrics';

class ExtendedPrismaClient extends PrismaClient {
  constructor() {
    super();
    return this.$extends(metricsExtension) as this;
  }
}

@Injectable()
export class PrismaRepository extends ExtendedPrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
