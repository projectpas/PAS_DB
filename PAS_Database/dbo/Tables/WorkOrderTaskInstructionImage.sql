/***************************************************************  
 ** File:   [WorkOrderTaskInstructionImage]             
 ** Author:   SUMIT KUMAR
 ** Description: Stores S3 metadata for images attached to Work Order Task Instructions [PN-17814]
 ** Date:  04-Sep-2026
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    04-Sep-2026		SUMIT KUMAR			Created [PN-17814]
 **************************************************************/
CREATE TABLE [dbo].[WorkOrderTaskInstructionImage] (
    [WorkOrderTaskInstructionImageId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderTaskInstructionId]      BIGINT          NOT NULL,
    [WorkOrderTaskId]                 BIGINT          NULL,
    [FileName]                        VARCHAR (500)   NULL,
    [Link]                            VARCHAR (1000)  NULL,
    [FileType]                        VARCHAR (100)   NULL,
    [FileSize]                        DECIMAL (18, 2) NULL,
    [MasterCompanyId]                 INT             NOT NULL,
    [CreatedBy]                       VARCHAR (100)   NOT NULL,
    [UpdatedBy]                       VARCHAR (100)   NOT NULL,
    [CreatedDate]                     DATETIME2 (7)   CONSTRAINT [DF_WorkOrderTaskInstructionImage_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7)   CONSTRAINT [DF_WorkOrderTaskInstructionImage_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                        BIT             CONSTRAINT [DF_WorkOrderTaskInstructionImage_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT             CONSTRAINT [DF_WorkOrderTaskInstructionImage_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderTaskInstructionImage] PRIMARY KEY CLUSTERED ([WorkOrderTaskInstructionImageId] ASC),
    CONSTRAINT [FK_WorkOrderTaskInstructionImage_WorkOrderTaskInstruction] FOREIGN KEY ([WorkOrderTaskInstructionId]) REFERENCES [dbo].[WorkOrderTaskInstruction] ([WorkOrderTaskInstructionId])
);

GO
CREATE NONCLUSTERED INDEX [IX_WorkOrderTaskInstructionImage_WorkOrderTaskInstructionId]
    ON [dbo].[WorkOrderTaskInstructionImage]([WorkOrderTaskInstructionId] ASC)
    INCLUDE([FileName], [Link], [FileType], [FileSize], [IsActive], [IsDeleted]);
