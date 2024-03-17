-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "cube";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "earthdistance";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "public";

-- CreateTable
CREATE TABLE "activity" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "albumId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "assetId" UUID,
    "comment" TEXT,
    "isLiked" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "PK_24625a1d6b1b089c8ae206fe467" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "albums" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "ownerId" UUID NOT NULL,
    "albumName" VARCHAR NOT NULL DEFAULT 'Untitled Album',
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "albumThumbnailAssetId" UUID,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "description" TEXT NOT NULL DEFAULT '',
    "deletedAt" TIMESTAMPTZ(6),
    "isActivityEnabled" BOOLEAN NOT NULL DEFAULT true,
    "order" VARCHAR NOT NULL DEFAULT 'desc',

    CONSTRAINT "PK_7f71c7b5bc7c87b8f94c9a93a00" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "albums_assets_assets" (
    "albumsId" UUID NOT NULL,
    "assetsId" UUID NOT NULL,

    CONSTRAINT "PK_c67bc36fa845fb7b18e0e398180" PRIMARY KEY ("albumsId","assetsId")
);

-- CreateTable
CREATE TABLE "albums_shared_users_users" (
    "albumsId" UUID NOT NULL,
    "usersId" UUID NOT NULL,

    CONSTRAINT "PK_7df55657e0b2e8b626330a0ebc8" PRIMARY KEY ("albumsId","usersId")
);

-- CreateTable
CREATE TABLE "api_keys" (
    "name" VARCHAR NOT NULL,
    "key" VARCHAR NOT NULL,
    "userId" UUID NOT NULL,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),

    CONSTRAINT "PK_5c8a79801b44bd27b79228e1dad" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "asset_faces" (
    "assetId" UUID NOT NULL,
    "personId" UUID,
    "embedding" vector NOT NULL,
    "imageWidth" INTEGER NOT NULL DEFAULT 0,
    "imageHeight" INTEGER NOT NULL DEFAULT 0,
    "boundingBoxX1" INTEGER NOT NULL DEFAULT 0,
    "boundingBoxY1" INTEGER NOT NULL DEFAULT 0,
    "boundingBoxX2" INTEGER NOT NULL DEFAULT 0,
    "boundingBoxY2" INTEGER NOT NULL DEFAULT 0,
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),

    CONSTRAINT "PK_6df76ab2eb6f5b57b7c2f1fc684" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "asset_job_status" (
    "assetId" UUID NOT NULL,
    "facesRecognizedAt" TIMESTAMPTZ(6),
    "metadataExtractedAt" TIMESTAMPTZ(6),

    CONSTRAINT "PK_420bec36fc02813bddf5c8b73d4" PRIMARY KEY ("assetId")
);

-- CreateTable
CREATE TABLE "asset_stack" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "primaryAssetId" UUID NOT NULL,

    CONSTRAINT "PK_74a27e7fcbd5852463d0af3034b" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "assets" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "deviceAssetId" VARCHAR NOT NULL,
    "ownerId" UUID NOT NULL,
    "deviceId" VARCHAR NOT NULL,
    "type" VARCHAR NOT NULL,
    "originalPath" VARCHAR NOT NULL,
    "resizePath" VARCHAR,
    "fileCreatedAt" TIMESTAMPTZ(6) NOT NULL,
    "fileModifiedAt" TIMESTAMPTZ(6) NOT NULL,
    "isFavorite" BOOLEAN NOT NULL DEFAULT false,
    "duration" VARCHAR,
    "webpPath" VARCHAR DEFAULT '',
    "encodedVideoPath" VARCHAR DEFAULT '',
    "checksum" BYTEA NOT NULL,
    "isVisible" BOOLEAN NOT NULL DEFAULT true,
    "livePhotoVideoId" UUID,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "originalFileName" VARCHAR NOT NULL,
    "sidecarPath" VARCHAR,
    "isReadOnly" BOOLEAN NOT NULL DEFAULT false,
    "thumbhash" BYTEA,
    "isOffline" BOOLEAN NOT NULL DEFAULT false,
    "libraryId" UUID NOT NULL,
    "isExternal" BOOLEAN NOT NULL DEFAULT false,
    "deletedAt" TIMESTAMPTZ(6),
    "localDateTime" TIMESTAMPTZ(6) NOT NULL,
    "stackId" UUID,

    CONSTRAINT "PK_da96729a8b113377cfb6a62439c" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit" (
    "id" SERIAL NOT NULL,
    "entityType" VARCHAR NOT NULL,
    "entityId" UUID NOT NULL,
    "action" VARCHAR NOT NULL,
    "ownerId" UUID NOT NULL,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PK_1d3d120ddaf7bc9b1ed68ed463a" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exif" (
    "assetId" UUID NOT NULL,
    "make" VARCHAR,
    "model" VARCHAR,
    "exifImageWidth" INTEGER,
    "exifImageHeight" INTEGER,
    "fileSizeInByte" BIGINT,
    "orientation" VARCHAR,
    "dateTimeOriginal" TIMESTAMPTZ(6),
    "modifyDate" TIMESTAMPTZ(6),
    "lensModel" VARCHAR,
    "fNumber" DOUBLE PRECISION,
    "focalLength" DOUBLE PRECISION,
    "iso" INTEGER,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "city" VARCHAR,
    "state" VARCHAR,
    "country" VARCHAR,
    "description" TEXT NOT NULL DEFAULT '',
    "fps" DOUBLE PRECISION,
    "exposureTime" VARCHAR,
    "livePhotoCID" VARCHAR,
    "timeZone" VARCHAR,
    "exifTextSearchableColumn" tsvector NOT NULL DEFAULT to_tsvector('english'::regconfig, (((((((((((((COALESCE(make, ''::character varying))::text || ' '::text) || (COALESCE(model, ''::character varying))::text) || ' '::text) || (COALESCE(orientation, ''::character varying))::text) || ' '::text) || (COALESCE("lensModel", ''::character varying))::text) || ' '::text) || (COALESCE(city, ''::character varying))::text) || ' '::text) || (COALESCE(state, ''::character varying))::text) || ' '::text) || (COALESCE(country, ''::character varying))::text)),
    "projectionType" VARCHAR,
    "profileDescription" VARCHAR,
    "colorspace" VARCHAR,
    "bitsPerSample" INTEGER,
    "autoStackId" VARCHAR,

    CONSTRAINT "PK_c0117fdbc50b917ef9067740c44" PRIMARY KEY ("assetId")
);

-- CreateTable
CREATE TABLE "geodata_places" (
    "id" INTEGER NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "countryCode" CHAR(2) NOT NULL,
    "admin1Code" VARCHAR(20),
    "admin2Code" VARCHAR(80),
    "modificationDate" DATE NOT NULL,
    "earthCoord" cube DEFAULT ll_to_earth(latitude, longitude),
    "admin1Name" VARCHAR,
    "admin2Name" VARCHAR,
    "alternateNames" VARCHAR,

    CONSTRAINT "PK_c29918988912ef4036f3d7fbff4" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "libraries" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "name" VARCHAR NOT NULL,
    "ownerId" UUID NOT NULL,
    "type" VARCHAR NOT NULL,
    "importPaths" TEXT[],
    "exclusionPatterns" TEXT[],
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMPTZ(6),
    "refreshedAt" TIMESTAMPTZ(6),
    "isVisible" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "PK_505fedfcad00a09b3734b4223de" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "migrations" (
    "id" SERIAL NOT NULL,
    "timestamp" BIGINT NOT NULL,
    "name" VARCHAR NOT NULL,

    CONSTRAINT "PK_8c82d7f526340ab734260ea46be" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "move_history" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "entityId" VARCHAR NOT NULL,
    "pathType" VARCHAR NOT NULL,
    "oldPath" VARCHAR NOT NULL,
    "newPath" VARCHAR NOT NULL,

    CONSTRAINT "PK_af608f132233acf123f2949678d" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "partners" (
    "sharedById" UUID NOT NULL,
    "sharedWithId" UUID NOT NULL,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "inTimeline" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "PK_f1cc8f73d16b367f426261a8736" PRIMARY KEY ("sharedById","sharedWithId")
);

-- CreateTable
CREATE TABLE "person" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ownerId" UUID NOT NULL,
    "name" VARCHAR NOT NULL DEFAULT '',
    "thumbnailPath" VARCHAR NOT NULL DEFAULT '',
    "isHidden" BOOLEAN NOT NULL DEFAULT false,
    "birthDate" DATE,
    "faceAssetId" UUID,

    CONSTRAINT "PK_5fdaf670315c4b7e70cce85daa3" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shared_link__asset" (
    "assetsId" UUID NOT NULL,
    "sharedLinksId" UUID NOT NULL,

    CONSTRAINT "PK_9b4f3687f9b31d1e311336b05e3" PRIMARY KEY ("assetsId","sharedLinksId")
);

-- CreateTable
CREATE TABLE "shared_links" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "description" VARCHAR,
    "userId" UUID NOT NULL,
    "key" BYTEA NOT NULL,
    "type" VARCHAR NOT NULL,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMPTZ(6),
    "allowUpload" BOOLEAN NOT NULL DEFAULT false,
    "albumId" UUID,
    "allowDownload" BOOLEAN NOT NULL DEFAULT true,
    "showExif" BOOLEAN NOT NULL DEFAULT true,
    "password" VARCHAR,

    CONSTRAINT "PK_642e2b0f619e4876e5f90a43465" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "smart_info" (
    "assetId" UUID NOT NULL,
    "tags" TEXT[],
    "objects" TEXT[],
    "smartInfoTextSearchableColumn" tsvector NOT NULL DEFAULT to_tsvector('english'::regconfig, f_concat_ws(' '::text, (COALESCE(tags, ARRAY[]::text[]) || COALESCE(objects, ARRAY[]::text[])))),

    CONSTRAINT "PK_5e3753aadd956110bf3ec0244ac" PRIMARY KEY ("assetId")
);

-- CreateTable
CREATE TABLE "smart_search" (
    "assetId" UUID NOT NULL,
    "embedding" vector NOT NULL,

    CONSTRAINT "smart_search_pkey" PRIMARY KEY ("assetId")
);

-- CreateTable
CREATE TABLE "socket_io_attachments" (
    "id" BIGSERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) DEFAULT CURRENT_TIMESTAMP,
    "payload" BYTEA
);

-- CreateTable
CREATE TABLE "system_config" (
    "key" VARCHAR NOT NULL,
    "value" VARCHAR,

    CONSTRAINT "PK_aab69295b445016f56731f4d535" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "system_metadata" (
    "key" VARCHAR NOT NULL,
    "value" JSONB NOT NULL DEFAULT '{}',

    CONSTRAINT "PK_fa94f6857470fb5b81ec6084465" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "tag_asset" (
    "assetsId" UUID NOT NULL,
    "tagsId" UUID NOT NULL,

    CONSTRAINT "PK_ef5346fe522b5fb3bc96454747e" PRIMARY KEY ("assetsId","tagsId")
);

-- CreateTable
CREATE TABLE "tags" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "type" VARCHAR NOT NULL,
    "name" VARCHAR NOT NULL,
    "userId" UUID NOT NULL,
    "renameTagId" UUID,

    CONSTRAINT "PK_e7dc17249a1148a1970748eda99" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_token" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "token" VARCHAR NOT NULL,
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" UUID NOT NULL,
    "deviceType" VARCHAR NOT NULL DEFAULT '',
    "deviceOS" VARCHAR NOT NULL DEFAULT '',

    CONSTRAINT "PK_48cb6b5c20faa63157b3c1baf7f" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "email" VARCHAR NOT NULL,
    "password" VARCHAR NOT NULL DEFAULT '',
    "createdAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "profileImagePath" VARCHAR NOT NULL DEFAULT '',
    "isAdmin" BOOLEAN NOT NULL DEFAULT false,
    "shouldChangePassword" BOOLEAN NOT NULL DEFAULT true,
    "deletedAt" TIMESTAMPTZ(6),
    "oauthId" VARCHAR NOT NULL DEFAULT '',
    "updatedAt" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "storageLabel" VARCHAR,
    "memoriesEnabled" BOOLEAN NOT NULL DEFAULT true,
    "name" VARCHAR NOT NULL DEFAULT '',
    "avatarColor" VARCHAR,
    "quotaSizeInBytes" BIGINT,
    "quotaUsageInBytes" BIGINT NOT NULL DEFAULT 0,
    "status" VARCHAR NOT NULL DEFAULT 'active',

    CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "IDX_4bd1303d199f4e72ccdf998c62" ON "albums_assets_assets"("assetsId");

-- CreateIndex
CREATE INDEX "IDX_e590fa396c6898fcd4a50e4092" ON "albums_assets_assets"("albumsId");

-- CreateIndex
CREATE INDEX "IDX_427c350ad49bd3935a50baab73" ON "albums_shared_users_users"("albumsId");

-- CreateIndex
CREATE INDEX "IDX_f48513bf9bccefd6ff3ad30bd0" ON "albums_shared_users_users"("usersId");

-- CreateIndex
CREATE INDEX "IDX_asset_faces_assetId_personId" ON "asset_faces"("assetId", "personId");

-- CreateIndex
CREATE INDEX "IDX_asset_faces_on_assetId" ON "asset_faces"("assetId");

-- CreateIndex
CREATE INDEX "IDX_asset_faces_personId" ON "asset_faces"("personId");

-- CreateIndex
CREATE INDEX "IDX_bf339a24070dac7e71304ec530" ON "asset_faces"("personId", "assetId");

-- CreateIndex
CREATE INDEX "face_index" ON "asset_faces"("embedding");

-- CreateIndex
CREATE UNIQUE INDEX "REL_91704e101438fd0653f582426d" ON "asset_stack"("primaryAssetId");

-- CreateIndex
CREATE UNIQUE INDEX "UQ_16294b83fa8c0149719a1f631ef" ON "assets"("livePhotoVideoId");

-- CreateIndex
CREATE INDEX "IDX_4d66e76dada1ca180f67a205dc" ON "assets"("originalFileName");

-- CreateIndex
CREATE INDEX "IDX_8d3efe36c0755849395e6ea866" ON "assets"("checksum");

-- CreateIndex
CREATE INDEX "IDX_asset_id_stackId" ON "assets"("id", "stackId");

-- CreateIndex
CREATE INDEX "IDX_originalPath_libraryId" ON "assets"("originalPath", "libraryId");

-- CreateIndex
CREATE INDEX "idx_asset_file_created_at" ON "assets"("fileCreatedAt");

-- CreateIndex
CREATE UNIQUE INDEX "UQ_assets_owner_library_checksum" ON "assets"("ownerId", "libraryId", "checksum");

-- CreateIndex
CREATE INDEX "IDX_ownerId_createdAt" ON "audit"("ownerId", "createdAt");

-- CreateIndex
CREATE INDEX "IDX_auto_stack_id" ON "exif"("autoStackId");

-- CreateIndex
CREATE INDEX "IDX_live_photo_cid" ON "exif"("livePhotoCID");

-- CreateIndex
CREATE INDEX "exif_city" ON "exif"("city");

-- CreateIndex
CREATE INDEX "IDX_geodata_gist_earthcoord" ON "geodata_places" USING GIST ("earthCoord");

-- CreateIndex
CREATE UNIQUE INDEX "UQ_newPath" ON "move_history"("newPath");

-- CreateIndex
CREATE UNIQUE INDEX "UQ_entityId_pathType" ON "move_history"("entityId", "pathType");

-- CreateIndex
CREATE INDEX "IDX_5b7decce6c8d3db9593d6111a6" ON "shared_link__asset"("assetsId");

-- CreateIndex
CREATE INDEX "IDX_c9fab4aa97ffd1b034f3d6581a" ON "shared_link__asset"("sharedLinksId");

-- CreateIndex
CREATE UNIQUE INDEX "UQ_sharedlink_key" ON "shared_links"("key");

-- CreateIndex
CREATE INDEX "IDX_sharedlink_albumId" ON "shared_links"("albumId");

-- CreateIndex
CREATE INDEX "IDX_sharedlink_key" ON "shared_links"("key");

-- CreateIndex
CREATE INDEX "si_tags" ON "smart_info" USING GIN ("tags");

-- CreateIndex
CREATE INDEX "smart_info_text_searchable_idx" ON "smart_info" USING GIN ("smartInfoTextSearchableColumn");

-- CreateIndex
CREATE INDEX "clip_index" ON "smart_search"("embedding");

-- CreateIndex
CREATE UNIQUE INDEX "socket_io_attachments_id_key" ON "socket_io_attachments"("id");

-- CreateIndex
CREATE INDEX "IDX_e99f31ea4cdf3a2c35c7287eb4" ON "tag_asset"("tagsId");

-- CreateIndex
CREATE INDEX "IDX_f8e8a9e893cb5c54907f1b798e" ON "tag_asset"("assetsId");

-- CreateIndex
CREATE INDEX "IDX_tag_asset_assetsId_tagsId" ON "tag_asset"("assetsId", "tagsId");

-- CreateIndex
CREATE UNIQUE INDEX "UQ_tag_name_userId" ON "tags"("name", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "UQ_97672ac88f789774dd47f7c8be3" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "UQ_b309cf34fa58137c416b32cea3a" ON "users"("storageLabel");

-- AddForeignKey
ALTER TABLE "activity" ADD CONSTRAINT "FK_1af8519996fbfb3684b58df280b" FOREIGN KEY ("albumId") REFERENCES "albums"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity" ADD CONSTRAINT "FK_3571467bcbe021f66e2bdce96ea" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity" ADD CONSTRAINT "FK_8091ea76b12338cb4428d33d782" FOREIGN KEY ("assetId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "albums" ADD CONSTRAINT "FK_05895aa505a670300d4816debce" FOREIGN KEY ("albumThumbnailAssetId") REFERENCES "assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "albums" ADD CONSTRAINT "FK_b22c53f35ef20c28c21637c85f4" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "albums_assets_assets" ADD CONSTRAINT "FK_4bd1303d199f4e72ccdf998c621" FOREIGN KEY ("assetsId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "albums_assets_assets" ADD CONSTRAINT "FK_e590fa396c6898fcd4a50e40927" FOREIGN KEY ("albumsId") REFERENCES "albums"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "albums_shared_users_users" ADD CONSTRAINT "FK_427c350ad49bd3935a50baab737" FOREIGN KEY ("albumsId") REFERENCES "albums"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "albums_shared_users_users" ADD CONSTRAINT "FK_f48513bf9bccefd6ff3ad30bd06" FOREIGN KEY ("usersId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "api_keys" ADD CONSTRAINT "FK_6c2e267ae764a9413b863a29342" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asset_faces" ADD CONSTRAINT "FK_02a43fd0b3c50fb6d7f0cb7282c" FOREIGN KEY ("assetId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asset_faces" ADD CONSTRAINT "FK_95ad7106dd7b484275443f580f9" FOREIGN KEY ("personId") REFERENCES "person"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asset_job_status" ADD CONSTRAINT "FK_420bec36fc02813bddf5c8b73d4" FOREIGN KEY ("assetId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "asset_stack" ADD CONSTRAINT "FK_91704e101438fd0653f582426dc" FOREIGN KEY ("primaryAssetId") REFERENCES "assets"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "assets" ADD CONSTRAINT "FK_16294b83fa8c0149719a1f631ef" FOREIGN KEY ("livePhotoVideoId") REFERENCES "assets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assets" ADD CONSTRAINT "FK_2c5ac0d6fb58b238fd2068de67d" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assets" ADD CONSTRAINT "FK_9977c3c1de01c3d848039a6b90c" FOREIGN KEY ("libraryId") REFERENCES "libraries"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "assets" ADD CONSTRAINT "FK_f15d48fa3ea5e4bda05ca8ab207" FOREIGN KEY ("stackId") REFERENCES "asset_stack"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exif" ADD CONSTRAINT "FK_c0117fdbc50b917ef9067740c44" FOREIGN KEY ("assetId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "libraries" ADD CONSTRAINT "FK_0f6fc2fb195f24d19b0fb0d57c1" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "partners" ADD CONSTRAINT "FK_7e077a8b70b3530138610ff5e04" FOREIGN KEY ("sharedById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "partners" ADD CONSTRAINT "FK_d7e875c6c60e661723dbf372fd3" FOREIGN KEY ("sharedWithId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "person" ADD CONSTRAINT "FK_2bbabe31656b6778c6b87b61023" FOREIGN KEY ("faceAssetId") REFERENCES "asset_faces"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "person" ADD CONSTRAINT "FK_5527cc99f530a547093f9e577b6" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shared_link__asset" ADD CONSTRAINT "FK_5b7decce6c8d3db9593d6111a66" FOREIGN KEY ("assetsId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shared_link__asset" ADD CONSTRAINT "FK_c9fab4aa97ffd1b034f3d6581ab" FOREIGN KEY ("sharedLinksId") REFERENCES "shared_links"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shared_links" ADD CONSTRAINT "FK_0c6ce9058c29f07cdf7014eac66" FOREIGN KEY ("albumId") REFERENCES "albums"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shared_links" ADD CONSTRAINT "FK_66fe3837414c5a9f1c33ca49340" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "smart_info" ADD CONSTRAINT "FK_5e3753aadd956110bf3ec0244ac" FOREIGN KEY ("assetId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "smart_search" ADD CONSTRAINT "smart_search_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tag_asset" ADD CONSTRAINT "FK_e99f31ea4cdf3a2c35c7287eb42" FOREIGN KEY ("tagsId") REFERENCES "tags"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "tag_asset" ADD CONSTRAINT "FK_f8e8a9e893cb5c54907f1b798e9" FOREIGN KEY ("assetsId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tags" ADD CONSTRAINT "FK_92e67dc508c705dd66c94615576" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "user_token" ADD CONSTRAINT "FK_d37db50eecdf9b8ce4eedd2f918" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE assets ADD COLUMN "truncatedDate" timestamptz GENERATED ALWAYS AS (date_trunc('month', "localDateTime" AT TIME ZONE 'UTC') AT TIME ZONE 'UTC') STORED;
