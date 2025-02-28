/*************************************************************           
 ** File:   [USP_CreateWorkOrder]           
 ** Author:   HEMANT SALIYA
 ** Description: This stored procedure is used to Create Work Order Quote
 ** Purpose:         
 ** Date:   24/02/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    24/02/2025   HEMANT SALIYA    Created
     
--   EXEC [USP_CreateWorkOrder] 
**************************************************************/
CREATE   PROCEDURE USP_CreateWorkOrder
    @CSRId INT,
    @SalesPersonId INT,
	@OpenDate DATE,
    @WorkOrderTypeId BIGINT,
    @MasterCompanyId BIGINT,
    @WorkOrderId BIGINT,
    @CreatedBy BIGINT,    
    @PartNumbers NVARCHAR(MAX),  -- Assuming you will pass the part numbers as JSON or CSV
    @StockLineId INT,
    @IsTraveler BIT,
    @AllowInvoiceBeforeShipping BIT
AS
BEGIN
    -- Declare variables
    DECLARE @CurrentNo INT = 0;
    DECLARE @CodePrefix NVARCHAR(50);
    DECLARE @CodeSuffix NVARCHAR(50);	
	DECLARE @WorkOrderNum NVARCHAR(50);
	DECLARE @WorkOrderSettingId BIGINT;

    -- Set CSRId and SalesPersonId to NULL if 0
    IF @CSRId = 0
        SET @CSRId = NULL;
    IF @SalesPersonId = 0
        SET @SalesPersonId = NULL;

    -- Fetch WorkOrderSettings based on parameters
    SELECT TOP 1 @WorkOrderSettingId = WorkOrderSettingId
    FROM dbo.WorkOrderSettings WITH(NOLOCK) WHERE WorkOrderTypeId = @WorkOrderTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

    -- Determine WorkOrder Code Prefix and Number
    IF @WorkOrderTypeId = 1 -- Customer
    BEGIN
        SELECT TOP 1 @CodePrefix = CodePrefix, @CodeSuffix = CodeSufix
        FROM dbo.CodePrefixes WITH(NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = 1 AND MasterCompanyId = @MasterCompanyId;
    END
    ELSE IF @WorkOrderTypeId = 2 -- Internal
    BEGIN
        SELECT TOP 1 @CodePrefix = CodePrefix, @CodeSuffix = CodeSufix 
        FROM dbo.CodePrefixes WITH(NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = 2 AND MasterCompanyId = @MasterCompanyId;
    END
	ELSE IF @WorkOrderTypeId = 3 -- TearDown
    BEGIN
        SELECT TOP 1 @CodePrefix = CodePrefix, @CodeSuffix = CodeSufix 
        FROM dbo.CodePrefixes WITH(NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = 3 AND MasterCompanyId = @MasterCompanyId;
    END
	ELSE IF @WorkOrderTypeId = 4 -- ShopServices
    BEGIN
        SELECT TOP 1 @CodePrefix = CodePrefix, @CodeSuffix = CodeSufix 
        FROM dbo.CodePrefixes WITH(NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND CodeTypeId = 4 AND MasterCompanyId = @MasterCompanyId;
    END
    -- Repeat for other WorkOrderTypes...

    -- Check for current number and increment
    IF @CodePrefix IS NOT NULL
    BEGIN
        SELECT @CurrentNo = ISNULL(CurrentNummber, 0) FROM dbo.CodePrefixes WITH(NOLOCK) WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
        
        IF @CurrentNo > 0
        BEGIN
            SET @CurrentNo = @CurrentNo + 1;
            UPDATE CodePrefixes 
            SET CurrentNummber = @CurrentNo
            WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
        END
        ELSE
        BEGIN
            SET @CurrentNo = (SELECT ISNULL(StartsFrom, 0)  FROM CodePrefixes WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId) + 1;
            UPDATE CodePrefixes
            SET CurrentNummber = @CurrentNo 
            WHERE CodePrefix = @CodePrefix AND MasterCompanyId = @MasterCompanyId;
        END
		-- Generate Work Order Number
		SET @WorkOrderNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
    END
	ELSE
	BEGIN
		-- Generate Work Order Number
		SET @WorkOrderNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo, '',''))
	END

    -- Insert or Update WorkOrder table (simplified)
    INSERT INTO WorkOrder(WorkOrderNum, OpenDate, CSRId, SalesPersonId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, MasterCompanyId)
    SELECT   @WorkOrderNum, @OpenDate, @CSRId,@SalesPersonId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(), 1, 0, @MasterCompanyId
  

    -- Iterate over PartNumbers and update accordingly (simplified, needs a loop)
    -- Assuming part numbers are passed as a string, you would need to parse them (like CSV or JSON)
    -- Example of parsing and updating PartNumbers

    -- Assuming you have logic to update part numbers




END;