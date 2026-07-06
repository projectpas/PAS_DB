/*************************************************************               
 ** File:   [GetWorkFlowWithMaterialList]              
 ** Author:   Ayushi Patel      
 ** Description: Get Work Flow With Material List by WorkflowId  
 ** Purpose:             
 ** Date:   07-April-2025           
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 **  S NO   Date         Author    Change Description                
 **  --   --------      --------  --------------------------------              
      1  07-April-2025   Ayushi   created      
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
  
-- EXEC GetWorkFlowWithMaterialList 80
**************************************************************/
CREATE   PROCEDURE GetWorkFlowWithMaterialList
    @WorkflowId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#MaterialList') IS NOT NULL
        DROP TABLE #MaterialList;


		SELECT 
		w.WorkflowId, w.WorkflowDescription, w.Version, w.WorkScopeId, w.ItemMasterId, 
		w.PartNumberDescription, w.CustomerId, w.CurrencyId, w.WorkflowExpirationDate, 
		w.IsCalculatedBERThreshold, ISNULL(w.IsFixedAmount,0)IsFixedAmount, w.FixedAmount, ISNULL(w.IsPercentageOfNew,0)IsPercentageOfNew, 
		w.CostOfNew, w.PercentageOfNew,ISNULL(w.IsPercentageOfReplacement,0)IsPercentageOfReplacement, w.CostOfReplacement, 
		w.PercentageOfReplacement, w.Memo, w.ManagementStructureId, w.MasterCompanyId, 
		w.CreatedBy, w.UpdatedBy, w.CreatedDate, w.UpdatedDate, ISNULL(w.IsActive,0)IsActive, ISNULL(w.IsDeleted,0)IsDeleted, 
		w.PartNumber, w.CustomerName, w.FlatRate, w.BERThresholdAmount, w.WorkOrderNumber, 
		w.CustomerCode, w.OtherCost, w.WorkflowCreateDate, w.ChangedPartNumberId, 
		w.PercentageOfMaterial, w.PercentageOfExpertise, w.PercentageOfCharges, 
		w.PercentageOfOthers, w.PercentageOfTotal, w.RevisedPartNumber, 
		w.changedPartNumberDescription, w.ChangedPartNumber, w.WorkScope, w.Currency, 
		w.WFParentId,ISNULL(w.IsVersionIncrease,0)IsVersionIncrease
	  INTO #tempWF
	FROM DBO.Workflow w WITH (NOLOCK)
  WHERE w.WorkflowId = @WorkflowId;

    CREATE TABLE #MaterialList
    (
        WorkflowMaterialListId BIGINT NOT NULL,
        WorkflowId BIGINT NOT NULL,
        ItemMasterId BIGINT NOT NULL,
        TaskId BIGINT NULL,
        Quantity SMALLINT NULL,
        UnitOfMeasureId BIGINT NULL,
        ConditionCodeId BIGINT NULL,
        UnitCost DECIMAL(18, 2) NULL,
        ExtendedCost DECIMAL(18, 2) NULL,
        Price DECIMAL(18, 2) NULL,
        ProvisionId INT NULL,
        IsDeferred BIT NULL,
        WorkflowActionId TINYINT NOT NULL,
        Memo NVARCHAR(MAX) NULL,
        MasterCompanyId INT NOT NULL,
        CreatedBy VARCHAR(256) NULL,
        UpdatedBy VARCHAR(256) NULL,
        CreatedDate DATETIME2(7) NOT NULL,
        UpdatedDate DATETIME2(7) NOT NULL,
        IsActive BIT NULL,
        IsDeleted BIT NOT NULL,
        MaterialMandatoriesName VARCHAR(256) NULL,
        PartNumber VARCHAR(256) NULL,
        PartDescription VARCHAR(MAX) NULL,
        ItemClassificationId BIGINT NULL,
        ExtendedPrice DECIMAL(18, 2) NULL,
        [Order] INT NULL,
        MaterialMandatoriesId INT NULL,
        WFParentId BIGINT NULL,
        IsVersionIncrease BIT NULL,
        Figure NVARCHAR(50) NULL,
        Item NVARCHAR(50) NULL,
        StockType NVARCHAR(50) NULL,
        ItemClassificationCode NVARCHAR(50) NULL,
        UnitOfMeasure NVARCHAR(50) NULL,
        ConditionName NVARCHAR(50) NULL
    );

	INSERT INTO #MaterialList (
		WorkflowMaterialListId, WorkflowId, ItemMasterId, TaskId, Quantity, 
		UnitOfMeasureId, ConditionCodeId, UnitCost, ExtendedCost, Price, 
		ProvisionId, IsDeferred, WorkflowActionId, Memo, MasterCompanyId, 
		CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, 
		MaterialMandatoriesName, PartNumber, PartDescription, ItemClassificationId, 
		ExtendedPrice, [Order], MaterialMandatoriesId, WFParentId, IsVersionIncrease, 
		Figure, Item, StockType, ItemClassificationCode, UnitOfMeasure, ConditionName
	)
	SELECT 
		WorkflowMaterialListId, WorkflowId, ItemMasterId, TaskId, Quantity, 
		UnitOfMeasureId, ConditionCodeId, UnitCost, ExtendedCost, Price, 
		ProvisionId, IsDeferred, WorkflowActionId, Memo, MasterCompanyId, 
		CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, 
		MaterialMandatoriesName, PartNumber, PartDescription, ItemClassificationId, 
		ExtendedPrice, [Order], MaterialMandatoriesId, WFParentId, IsVersionIncrease, 
		Figure, Item, NULL, NULL, NULL, NULL 
	FROM DBO.WorkflowMaterial wm WITH (NOLOCK)
	WHERE wm.WorkflowId = @WorkflowId 
	  AND (wm.IsDeleted IS NULL OR wm.IsDeleted <> 1)
	ORDER BY wm.WorkflowActionId;


    UPDATE ml
    SET ml.StockType = 
		CASE 
			WHEN ISNULL(im.IsPma, 0) = 1 AND ISNULL(im.IsDER, 0) = 1 THEN 'PMA&DER'
			WHEN ISNULL(im.IsPma, 0) = 1 AND ISNULL(im.IsDER, 0) = 0 THEN 'PMA'
			WHEN ISNULL(im.IsPma, 0) = 0 AND ISNULL(im.IsDER, 0) = 1 THEN 'DER'
			ELSE 'OEM'
		END
    FROM #MaterialList ml
    INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON ml.ItemMasterId = im.ItemMasterId WHERE ISNULL(im.IsNonStock,0) = 0
;

    UPDATE ml
    SET ml.ItemClassificationCode = ic.ItemClassificationCode
    FROM #MaterialList ml
    INNER JOIN DBO.ItemClassification ic WITH (NOLOCK) ON ml.ItemClassificationId = ic.ItemClassificationId;

    UPDATE ml
    SET ml.UnitOfMeasure = uom.Description
    FROM #MaterialList ml
    INNER JOIN DBO.UnitOfMeasure uom WITH (NOLOCK) ON ml.UnitOfMeasureId = uom.UnitOfMeasureId;

    UPDATE ml
    SET ml.ConditionName = c.Description
    FROM #MaterialList ml
    INNER JOIN DBO.Condition c WITH (NOLOCK) ON ml.ConditionCodeId = c.ConditionId;

    SELECT twf.WorkflowId,
  twf.WorkflowExpirationDate,
	twf.FixedAmount,
	twf.CostOfNew,
	twf.PercentageOfNew,
	twf.CostOfReplacement,
	twf.PercentageOfReplacement,
	twf.Memo,
	twf.BERThresholdAmount,
	twf.WorkOrderNumber,
	twf.OtherCost,
	twf.WorkflowCreateDate,
	twf.PercentageOfMaterial,
	twf.PercentageOfExpertise,
	twf.PercentageOfCharges,
	twf.PercentageOfOthers,
	twf.PercentageOfTotal FROM #tempWF twf

    SELECT ml.WorkflowMaterialListId,
  ml.TaskId,
	ml.Quantity,
	ml.UnitCost,
	ml.ExtendedCost,
	ml.Price,
	ISNULL(ml.IsDeferred,0) as IsDeferred,
	ml.Memo,
	ml.MaterialMandatoriesName,
	ml.PartNumber,
	ml.PartDescription,
	ml.Figure,
	ml.Item,
	ml.ItemClassificationCode,
	ml.UnitOfMeasure,
	ml.ConditionName FROM #MaterialList ml;

    SELECT im.ItemMasterId,im.partnumber FROM DBO.ItemMaster im WITH (NOLOCK) inner join #tempWF twf ON twf.ItemMasterId = im.ItemMasterId  WHERE ISNULL(im.IsNonStock,0) = 0
;
    SELECT ws.WorkScopeId,ws.Description,ws.WorkScopeCode FROM DBO.WorkScope ws WITH (NOLOCK) inner join #tempWF twf ON twf.WorkScopeId = ws.WorkScopeId ;
    
END;