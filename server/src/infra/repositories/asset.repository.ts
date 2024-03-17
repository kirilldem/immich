import {
  AssetCreate,
  AssetEntityWithoutRelations,
  AssetExploreFieldOptions,
  AssetPathEntity,
  AssetSearchOptions,
  AssetStats,
  AssetStatsOptions,
  IAssetRepository,
  LivePhotoSearchOptions,
  MapMarker,
  MapMarkerSearchOptions,
  MetadataSearchOptions,
  MonthDay,
  Paginated,
  PaginationMode,
  PaginationOptions,
  SearchExploreItem,
  TimeBucketItem,
  TimeBucketOptions,
  TimeBucketSize,
  WithProperty,
  WithoutProperty,
} from '@app/domain';
import { Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Prisma } from '@prisma/client';
import { DateTime } from 'luxon';
import { FindOptionsRelations, FindOptionsWhere, IsNull, Not, Repository } from 'typeorm';
import { AssetEntity, AssetJobStatusEntity, AssetOrder, AssetType, ExifEntity } from '../entities';
import { DummyValue, GenerateSql } from '../infra.util';
import { Chunked, ChunkedArray, paginate, paginatedBuilder, searchAssetBuilder } from '../infra.utils';
import { Instrumentation } from '../instrumentation';
import { PrismaRepository } from './prisma.repository';

@Instrumentation()
@Injectable()
export class AssetRepository implements IAssetRepository {
  constructor(
    @InjectRepository(AssetEntity) private repository: Repository<AssetEntity>,
    @Inject(PrismaRepository) private prismaRepository: PrismaRepository,
  ) {}

  async upsertExif(exif: Partial<ExifEntity> & { assetId: string }): Promise<void> {
    await this.prismaRepository.exif.upsert({ update: exif, create: exif, where: { assetId: exif.assetId } });
  }

  async upsertJobStatus(jobStatus: Partial<AssetJobStatusEntity> & { assetId: string }): Promise<void> {
    await this.prismaRepository.assetJobStatus.upsert({
      update: jobStatus,
      create: jobStatus,
      where: { assetId: jobStatus.assetId },
    });
  }

  async create(asset: AssetCreate): Promise<AssetEntity> {
    const { ownerId, libraryId, livePhotoVideoId, stackId, ...assetData } = asset;
    const res = await this.prismaRepository.assets.create({
      data: {
        ...assetData,
        livePhotoVideo: livePhotoVideoId ? { connect: { id: livePhotoVideoId } } : undefined,
        stack: stackId ? { connect: { id: stackId } } : undefined,
        library: { connect: { id: libraryId } },
        owner: { connect: { id: ownerId } },
      },
    });
    return res as any as AssetEntity;
  }

  @GenerateSql({ params: [DummyValue.UUID, { day: 1, month: 1 }] })
  async getByDayOfYear(ownerId: string, { day, month }: MonthDay): Promise<AssetEntity[]> {
    const date = DateTime.utc().set({ day, month });
    const res = await this.prismaRepository.assets.findMany({
      where: {
        ownerId,
        isVisible: true,
        isArchived: false,
        deletedAt: null,
        resizePath: { not: null },
        localDateTime: {
          gte: date.startOf('day').toJSDate(),
          lte: date.endOf('day').toJSDate(),
        },
      },
      include: {
        exifInfo: true,
      },
      orderBy: {
        localDateTime: 'desc',
      },
    });

    return res as any as AssetEntity[];
  }

  @GenerateSql({ params: [[DummyValue.UUID]] })
  @ChunkedArray()
  async getByIds(ids: string[], relations?: Prisma.AssetsInclude): Promise<AssetEntity[]> {
    const res = await this.prismaRepository.assets.findMany({
      where: { id: { in: ids }, deletedAt: null },
      include: {
        ...relations,
        library: relations?.library ? { include: { assets: true, owner: true } } : undefined,
      },
    });
    return res as any as AssetEntity[]; // typeorm type assumes arbitrary level of recursion
  }

  @GenerateSql({ params: [[DummyValue.UUID]] })
  @ChunkedArray()
  async getByIdsWithAllRelations(ids: string[]): Promise<AssetEntity[]> {
    const res = await this.prismaRepository.assets.findMany({
      where: { id: { in: ids }, deletedAt: null },
      include: {
        exifInfo: true,
        smartInfo: true,
        tags: true,
        faces: {
          include: {
            person: true,
          },
        },
        stack: { include: { assets: true } },
      },
    });

    return res as any as AssetEntity[];
  }

  @GenerateSql({ params: [DummyValue.UUID] })
  async deleteAll(ownerId: string): Promise<void> {
    await this.prismaRepository.assets.deleteMany({ where: { ownerId } });
  }

  getByAlbumId(pagination: PaginationOptions, albumId: string): Paginated<AssetEntity> {
    return paginate(this.repository, pagination, {
      where: {
        albums: {
          id: albumId,
        },
      },
      relations: {
        albums: true,
        exifInfo: true,
      },
    });
  }

  getByUserId(
    pagination: PaginationOptions,
    userId: string,
    options: Omit<AssetSearchOptions, 'userIds'> = {},
  ): Paginated<AssetEntity> {
    return this.getAll(pagination, { ...options, userIds: [userId] });
  }

  @GenerateSql({ params: [[DummyValue.UUID]] })
  getLibraryAssetPaths(pagination: PaginationOptions, libraryId: string): Paginated<AssetPathEntity> {
    return paginate(this.repository, pagination, {
      select: { id: true, originalPath: true, isOffline: true },
      where: { library: { id: libraryId } },
    });
  }

  @GenerateSql({ params: [DummyValue.UUID, DummyValue.STRING] })
  async getByLibraryIdAndOriginalPath(libraryId: string, originalPath: string): Promise<AssetEntity | null> {
    const res = await this.prismaRepository.assets.findFirst({ where: { libraryId, originalPath } });
    return res as AssetEntity | null;
  }

  getAll(pagination: PaginationOptions, options: AssetSearchOptions = {}): Paginated<AssetEntity> {
    let builder = this.repository.createQueryBuilder('asset');
    builder = searchAssetBuilder(builder, options);
    builder.orderBy('asset.createdAt', options.orderDirection ?? 'ASC');
    return paginatedBuilder<AssetEntity>(builder, {
      mode: PaginationMode.SKIP_TAKE,
      skip: pagination.skip,
      take: pagination.take,
    });
  }

  /**
   * Get assets by device's Id on the database
   * @param ownerId
   * @param deviceId
   *
   * @returns Promise<string[]> - Array of assetIds belong to the device
   */
  @GenerateSql({ params: [DummyValue.UUID, DummyValue.STRING] })
  async getAllByDeviceId(ownerId: string, deviceId: string): Promise<string[]> {
    const items = await this.prismaRepository.assets.findMany({
      where: {
        ownerId,
        deviceId,
        isVisible: true,
      },
      select: {
        deviceAssetId: true,
      },
    });

    return items.map((asset) => asset.deviceAssetId);
  }

  @GenerateSql({ params: [DummyValue.UUID] })
  async getById(id: string, relations: Prisma.AssetsInclude): Promise<AssetEntity | null> {
    const items = await this.prismaRepository.assets.findFirst({ where: { id }, include: relations });
    return items as any as AssetEntity | null;
  }

  @GenerateSql({ params: [[DummyValue.UUID], { deviceId: DummyValue.STRING }] })
  @Chunked()
  async updateAll(ids: string[], options: Partial<AssetEntity>): Promise<void> {
    await this.prismaRepository.assets.updateMany({ where: { id: { in: ids } }, data: options });
  }

  @Chunked()
  async softDeleteAll(ids: string[]): Promise<void> {
    await this.prismaRepository.assets.updateMany({ where: { id: { in: ids } }, data: { deletedAt: new Date() } });
  }

  @Chunked()
  async restoreAll(ids: string[]): Promise<void> {
    await this.prismaRepository.assets.updateMany({ where: { id: { in: ids } }, data: { deletedAt: null } });
  }

  async save(asset: AssetEntityWithoutRelations): Promise<AssetEntity> {
    const { ownerId, libraryId, livePhotoVideoId, stackId, ...assetData } = asset;

    const res = await this.prismaRepository.assets.upsert({
      update: assetData,
      create: {
        ...assetData,
        livePhotoVideo: livePhotoVideoId ? { connect: { id: livePhotoVideoId } } : undefined,
        owner: { connect: { id: ownerId } },
        library: { connect: { id: libraryId } },
        // stack: stackId
        //   ? {
        //       connectOrCreate: {
        //         create: { id: stackId, primaryAsset: { connect: { id: asset.id } } },
        //         where: { id: stackId },
        //       },
        //     }
        //   : undefined,
      },
      where: { id: asset.id },
      include: {
        exifInfo: true,
        smartInfo: true,
        tags: true,
        faces: {
          include: {
            person: true,
          },
        },
      },
    });

    return res as any as AssetEntity; // typeorm type assumes all relations are included
  }

  async remove(asset: AssetEntity): Promise<void> {
    await this.prismaRepository.assets.delete({ where: { id: asset.id } });
  }

  @GenerateSql({ params: [DummyValue.UUID, DummyValue.BUFFER] })
  async getByChecksum(userId: string, checksum: Buffer): Promise<AssetEntity | null> {
    const item = await this.prismaRepository.assets.findFirst({ where: { ownerId: userId, checksum: checksum } });
    return item as AssetEntity | null;
  }

  async findLivePhotoMatch(options: LivePhotoSearchOptions): Promise<AssetEntity | null> {
    const { ownerId, otherAssetId, livePhotoCID, type } = options;

    const item = await this.prismaRepository.assets.findFirst({
      where: {
        id: { not: otherAssetId },
        ownerId,
        type,
        exifInfo: {
          livePhotoCID,
        },
      },
      include: {
        exifInfo: true,
      },
    });
    return item as AssetEntity | null;
  }

  @GenerateSql(
    ...Object.values(WithProperty)
      .filter((property) => property !== WithProperty.IS_OFFLINE)
      .map((property) => ({
        name: property,
        params: [DummyValue.PAGINATION, property],
      })),
  )
  getWithout(pagination: PaginationOptions, property: WithoutProperty): Paginated<AssetEntity> {
    let relations: FindOptionsRelations<AssetEntity> = {};
    let where: FindOptionsWhere<AssetEntity> | FindOptionsWhere<AssetEntity>[] = {};

    switch (property) {
      case WithoutProperty.THUMBNAIL: {
        where = [
          { resizePath: IsNull(), isVisible: true },
          { resizePath: '', isVisible: true },
          { webpPath: IsNull(), isVisible: true },
          { webpPath: '', isVisible: true },
          { thumbhash: IsNull(), isVisible: true },
        ];
        break;
      }

      case WithoutProperty.ENCODED_VIDEO: {
        where = [
          { type: AssetType.VIDEO, encodedVideoPath: IsNull() },
          { type: AssetType.VIDEO, encodedVideoPath: '' },
        ];
        break;
      }

      case WithoutProperty.EXIF: {
        relations = {
          exifInfo: true,
          jobStatus: true,
        };
        where = {
          isVisible: true,
          jobStatus: {
            metadataExtractedAt: IsNull(),
          },
        };
        break;
      }

      case WithoutProperty.SMART_SEARCH: {
        relations = {
          smartSearch: true,
        };
        where = {
          isVisible: true,
          resizePath: Not(IsNull()),
          smartSearch: {
            embedding: IsNull(),
          },
        };
        break;
      }

      case WithoutProperty.OBJECT_TAGS: {
        relations = {
          smartInfo: true,
        };
        where = {
          resizePath: Not(IsNull()),
          isVisible: true,
          smartInfo: {
            tags: IsNull(),
          },
        };
        break;
      }

      case WithoutProperty.FACES: {
        relations = {
          faces: true,
          jobStatus: true,
        };
        where = {
          resizePath: Not(IsNull()),
          isVisible: true,
          faces: {
            assetId: IsNull(),
            personId: IsNull(),
          },
          jobStatus: {
            facesRecognizedAt: IsNull(),
          },
        };
        break;
      }

      case WithoutProperty.PERSON: {
        relations = {
          faces: true,
        };
        where = {
          resizePath: Not(IsNull()),
          isVisible: true,
          faces: {
            assetId: Not(IsNull()),
            personId: IsNull(),
          },
        };
        break;
      }

      case WithoutProperty.SIDECAR: {
        where = [
          { sidecarPath: IsNull(), isVisible: true },
          { sidecarPath: '', isVisible: true },
        ];
        break;
      }

      default: {
        throw new Error(`Invalid getWithout property: ${property}`);
      }
    }

    return paginate(this.repository, pagination, {
      relations,
      where,
      order: {
        // Ensures correct order when paginating
        createdAt: 'ASC',
      },
    });
  }

  getWith(pagination: PaginationOptions, property: WithProperty, libraryId?: string): Paginated<AssetEntity> {
    let where: FindOptionsWhere<AssetEntity> | FindOptionsWhere<AssetEntity>[] = {};

    switch (property) {
      case WithProperty.SIDECAR: {
        where = [{ sidecarPath: Not(IsNull()), isVisible: true }];
        break;
      }
      case WithProperty.IS_OFFLINE: {
        if (!libraryId) {
          throw new Error('Library id is required when finding offline assets');
        }
        where = [{ isOffline: true, libraryId: libraryId }];
        break;
      }

      default: {
        throw new Error(`Invalid getWith property: ${property}`);
      }
    }

    return paginate(this.repository, pagination, {
      where,
      order: {
        // Ensures correct order when paginating
        createdAt: 'ASC',
      },
    });
  }

  async getFirstAssetForAlbumId(albumId: string): Promise<AssetEntity | null> {
    const items = await this.prismaRepository.assets.findFirst({
      where: {
        albums: {
          some: {
            id: albumId,
          },
        },
      },
      orderBy: {
        fileCreatedAt: 'desc',
      },
    });

    return items as AssetEntity | null;
  }

  async getLastUpdatedAssetForAlbumId(albumId: string): Promise<AssetEntity | null> {
    const items = await this.prismaRepository.assets.findFirst({
      where: {
        albums: {
          some: {
            id: albumId,
          },
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    return items as AssetEntity | null;
  }

  async getMapMarkers(ownerIds: string[], options: MapMarkerSearchOptions = {}): Promise<MapMarker[]> {
    const { isArchived, isFavorite, fileCreatedAfter, fileCreatedBefore } = options;

    const assets = await this.prismaRepository.assets.findMany({
      select: {
        id: true,
        exifInfo: {
          select: {
            city: true,
            state: true,
            country: true,
            latitude: true,
            longitude: true,
          },
        },
      },
      where: {
        ownerId: {
          in: ownerIds,
        },
        isVisible: true,
        isArchived,
        exifInfo: {
          latitude: { not: null },
          longitude: { not: null },
        },
        isFavorite,
        fileCreatedAt: { gte: fileCreatedAfter, lte: fileCreatedBefore },
      },
      orderBy: {
        fileCreatedAt: 'desc',
      },
    });

    return assets.map((asset) => ({
      id: asset.id,
      lat: asset.exifInfo!.latitude!,
      lon: asset.exifInfo!.longitude!,
      city: asset.exifInfo!.city,
      state: asset.exifInfo!.state,
      country: asset.exifInfo!.country,
    }));
  }

  async getStatistics(ownerId: string, { isArchived, isFavorite, isTrashed }: AssetStatsOptions): Promise<AssetStats> {
    const items = await this.prismaRepository.assets.groupBy({
      by: 'type',
      where: {
        ownerId,
        isVisible: true,
        isArchived,
        isFavorite,
        deletedAt: isTrashed ? { not: null } : null,
      },
      _count: {
        id: true,
      },
    });

    const result: AssetStats = {
      [AssetType.AUDIO]: 0,
      [AssetType.IMAGE]: 0,
      [AssetType.VIDEO]: 0,
      [AssetType.OTHER]: 0,
    };

    for (const item of items) {
      result[item.type as AssetType] = item._count.id;
    }

    return result;
  }

  async getRandom(ownerId: string, take: number): Promise<AssetEntity[]> {
    const where = {
      ownerId,
      isVisible: true,
      deletedAt: null,
    };

    const count = await this.prismaRepository.assets.count({ where });
    const skip = Math.floor(Math.random() * Math.max(count - take, 0));
    const items = await this.prismaRepository.assets.findMany({ where, take, skip });

    return items as any as AssetEntity[];
  }

  @GenerateSql({ params: [{ size: TimeBucketSize.MONTH }] })
  async getTimeBuckets(options: TimeBucketOptions): Promise<TimeBucketItem[]> {
    const items = await this.prismaRepository.assets.groupBy({
      by: 'truncatedDate',
      where: {
        ownerId: {
          in: options.userIds,
        },
        isVisible: true,
        isArchived: options.isArchived,
        isFavorite: options.isFavorite,
        deletedAt: options.isTrashed ? { not: null } : null,
        albums: options.albumId ? { some: { id: options.albumId } } : undefined,
        faces: options.personId ? { some: { personId: options.personId } } : undefined,
        type: options.assetType,
      },
      _count: {
        id: true,
      },
      orderBy: {
        truncatedDate: 'desc',
      },
    });

    return items.map((item) => ({
      timeBucket: item.truncatedDate.toISOString(),
      count: item._count.id,
    }));
  }

  @GenerateSql({ params: [DummyValue.TIME_BUCKET, { size: TimeBucketSize.MONTH }] })
  async getTimeBucket(timeBucket: string, options: TimeBucketOptions): Promise<AssetEntity[]> {
    const items = await this.prismaRepository.assets.findMany({
      where: {
        ownerId: {
          in: options.userIds,
        },
        isVisible: true,
        isArchived: options.isArchived,
        isFavorite: options.isFavorite,
        deletedAt: options.isTrashed ? { not: null } : null,
        truncatedDate: timeBucket.replace(/^[+-]/, ''),
        albums: options.albumId ? { some: { id: options.albumId } } : undefined,
        faces: options.personId ? { some: { personId: options.personId } } : undefined,
        type: options.assetType,
      },
      orderBy: { fileCreatedAt: options.order === AssetOrder.ASC ? 'asc' : 'desc' },
      include: {
        owner: true,
        exifInfo: options.exifInfo,
        stack: options.withStacked ? { include: { assets: true } } : undefined,
      },
      relationLoadStrategy: 'query', // this seems faster than 'join' in this case
    });

    return items as any as AssetEntity[];
  }

  @GenerateSql({ params: [DummyValue.UUID, { minAssetsPerField: 5, maxFields: 12 }] })
  async getAssetIdByCity(
    ownerId: string,
    { minAssetsPerField, maxFields }: AssetExploreFieldOptions,
  ): Promise<SearchExploreItem<string>> {
    const res = await this.prismaRepository.exif.groupBy({
      by: 'city',
      where: {
        assets: { ownerId, isVisible: true, isArchived: false, deletedAt: null, type: AssetType.IMAGE },
        city: { not: null },
      },
      having: {
        assetId: {
          _count: {
            gte: minAssetsPerField,
          },
        },
      },
      take: maxFields,
      orderBy: {
        city: 'desc',
      },
    });

    const cities = res.map((item) => item.city!);

    const items = await this.prismaRepository.exif.findMany({
      where: {
        city: {
          in: cities,
        },
      },
      select: {
        city: true,
        assetId: true,
      },
      distinct: ['city'],
    });

    return {
      fieldName: 'exifInfo.city',
      items: items.map((item) => ({ value: item.city!, data: item.assetId })),
    };
  }

  @GenerateSql({ params: [DummyValue.UUID, { minAssetsPerField: 5, maxFields: 12 }] })
  async getAssetIdByTag(
    ownerId: string,
    { minAssetsPerField, maxFields }: AssetExploreFieldOptions,
  ): Promise<SearchExploreItem<string>> {
    const res = await this.prismaRepository.smartInfo.groupBy({
      by: 'tags',
      where: {
        assets: { ownerId, isVisible: true, isArchived: false, deletedAt: null, type: AssetType.IMAGE },
      },
      having: {
        assetId: {
          _count: {
            gte: minAssetsPerField,
          },
        },
      },
      take: maxFields,
      orderBy: {
        tags: 'desc',
      },
    });

    const tags = res.flatMap((item) => item.tags!);

    const items = await this.prismaRepository.smartInfo.findMany({
      where: {
        tags: {
          hasSome: tags,
        },
      },
      select: {
        tags: true,
        assetId: true,
      },
    });

    return {
      fieldName: 'smartInfo.tags',
      items: items.map((item) => ({ value: item.tags![0], data: item.assetId })),
    };
  }

  @GenerateSql({ params: [DummyValue.STRING, [DummyValue.UUID], { numResults: 250 }] })
  async searchMetadata(
    query: string,
    userIds: string[],
    { numResults }: MetadataSearchOptions,
  ): Promise<AssetEntity[]> {
    const items = await this.prismaRepository.assets.findMany({
      where: {
        ownerId: {
          in: userIds,
        },
        isVisible: true,
        isArchived: false,
        deletedAt: null,
        OR: [
          {
            originalFileName: {
              contains: query,
            },
          },
          {
            exifInfo: {
              city: {
                contains: query,
              },
            },
          },
          {
            exifInfo: {
              description: {
                contains: query,
              },
            },
          },
          {
            exifInfo: {
              lensModel: {
                contains: query,
              },
            },
          },
          {
            exifInfo: {
              make: {
                contains: query,
              },
            },
          },
          {
            exifInfo: {
              model: {
                contains: query,
              },
            },
          },
          {
            exifInfo: {
              state: {
                contains: query,
              },
            },
          },
          {
            exifInfo: {
              country: {
                contains: query,
              },
            },
          },
        ],
      },
      orderBy: {
        fileCreatedAt: 'desc',
      },
      take: numResults,
      include: {
        exifInfo: true,
        smartInfo: true,
      },
    });

    return items as any as AssetEntity[];
  }
}
