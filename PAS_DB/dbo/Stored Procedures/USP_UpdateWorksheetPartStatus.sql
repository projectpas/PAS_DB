

/*************************************************************             
 ** File:   [USP_UpdateWorksheetPartStatus]         
 ** Author:   
 ** Description: This stored procedure is used to get records from [WorksheetHeader].
 ** Purpose:           
 ** Date:  [14-May-2026] 
            
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------     
    1    14/05/2026                        Created [PN-16408]
**************************************************************/


CREATE PROCEDURE [dbo].[USP_UpdateWorksheetPartStatus]
(
    @WorksheetPartId BIGINT,
    @MasterCompanyId INT,
    @IsDeleted BIT = NULL,
    @IsActive BIT = NULL,
    @UpdatedBy VARCHAR(256) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.WorksheetPart
    SET
        IsDeleted = ISNULL(@IsDeleted, IsDeleted),
        IsActive = ISNULL(@IsActive, IsActive),
        UpdatedBy = ISNULL(@UpdatedBy, UpdatedBy),
        UpdatedDate = GETUTCDATE()
    WHERE WorksheetPartId = @WorksheetPartId AND MasterCompanyId = @MasterCompanyId;

    SELECT
        WorksheetPartId,
        IsDeleted,
        IsActive,
        UpdatedBy,
        UpdatedDate
    FROM dbo.WorksheetPart WITH(NOLOCK)
    WHERE WorksheetPartId = @WorksheetPartId And MasterCompanyId  = @MasterCompanyId;;

END