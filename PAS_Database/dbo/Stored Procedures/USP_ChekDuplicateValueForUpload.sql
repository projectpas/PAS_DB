/***************************************************************  
 ** File:   [USP_ChekDuplicateValueForUpload]             
 ** Author:   Devendra Shekh
 ** Description: This SP is used to return dropdownId based on passed table and values
 ** Date:  11-Dec-2024
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    03-Feb-2024		Devendra Shekh			Created

DECLARE @IsDuplicate BIT;

EXEC [dbo].[USP_ChekDuplicateValueForUpload]
    @ChekDuplticateRef1 = 'ItemMasterId',
    @ChekDuplticateRef2 = 'MappingItemMasterId',
    @DuplicateRefeValue1 = '14',
    @DuplicateRefeValue2 = '102605',
    @ReferenceTable = 'Nha_Tla_Alt_Equ_ItemMapping',
    @MasterCompanyId = 1,
    @ModuleId = 3,
    @IsDuplicate = @IsDuplicate OUTPUT;

SELECT @IsDuplicate AS IsDuplicateResult;

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ChekDuplicateValueForUpload] 
(
    @ChekDuplticateRef1    AS VARCHAR(150) = NULL,
    @ChekDuplticateRef2    AS VARCHAR(150) = NULL,
    @DuplicateRefeValue1   AS VARCHAR(150) = NULL,
    @DuplicateRefeValue2   AS VARCHAR(150) = NULL,
    @ReferenceTable        AS VARCHAR(150) = NULL,
    @MasterCompanyId       AS INT = NULL,
    @ModuleId              AS BIGINT = NULL,
    @IsDuplicate           BIT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RefQuery AS NVARCHAR(MAX) = '';
    DECLARE @Params AS NVARCHAR(MAX);
    DECLARE @AlterModule AS BIGINT;
    
    SET @AlterModule = (SELECT ImportModuleId FROM [DBO].[ImportModule] WITH(NOLOCK) WHERE [ModuleName] = 'AlternateItemMaster');
    SET @IsDuplicate = 0;
    
    SET @RefQuery = N'
        IF EXISTS (
            SELECT 1 FROM ' + QUOTENAME(@ReferenceTable) + N' WITH(NOLOCK)
            WHERE MasterCompanyId = @MasterCompanyId 
            AND ' + QUOTENAME(@ChekDuplticateRef1) + N' = @DuplicateRefeValue1 
            AND ' + QUOTENAME(@ChekDuplticateRef2) + N' = @DuplicateRefeValue2
        )
        BEGIN
            SET @IsDuplicate = 1;
        END';
    
    SET @Params = N'@MasterCompanyId INT, @DuplicateRefeValue1 VARCHAR(150), @DuplicateRefeValue2 VARCHAR(150), @IsDuplicate BIT OUTPUT';
    
    EXEC sp_executesql @RefQuery, @Params, 
        @MasterCompanyId = @MasterCompanyId, 
        @DuplicateRefeValue1 = @DuplicateRefeValue1, 
        @DuplicateRefeValue2 = @DuplicateRefeValue2, 
        @IsDuplicate = @IsDuplicate OUTPUT;
END;